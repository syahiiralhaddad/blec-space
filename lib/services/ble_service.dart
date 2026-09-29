import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../config/ble_config.dart';

/// One row in the "Nearby devices" list.
class NearbyDevice {
  NearbyDevice({required this.device, this.rssi});

  final BluetoothDevice device;
  final int? rssi;
}

/// Single place that owns all Bluetooth logic, so the screens only render state.
///
/// Screens listen to it with `ListenableBuilder(listenable: BleService.instance, ...)`.
class BleService extends ChangeNotifier {
  BleService._();
  static final BleService instance = BleService._();

  BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;
  bool isScanning = false;
  List<ScanResult> _scanResults = [];

  /// Devices we are connected to, keyed by their Bluetooth id.
  final Map<DeviceIdentifier, BluetoothDevice> connected = {};
  final Set<DeviceIdentifier> connecting = {};

  /// Device currently shown on the "Switch LED" card.
  DeviceIdentifier? activeDeviceId;

  final Map<DeviceIdentifier, BluetoothCharacteristic> _ledChars = {};
  final Map<DeviceIdentifier, bool> ledState = {};
  final Map<DeviceIdentifier, List<StreamSubscription>> _deviceSubs = {};
  final List<StreamSubscription> _globalSubs = [];
  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void init() {
    if (_initialized) return;
    _initialized = true;

    _globalSubs.add(FlutterBluePlus.adapterState.listen((state) {
      adapterState = state;
      notifyListeners();
    }));
    _globalSubs.add(FlutterBluePlus.isScanning.listen((value) {
      isScanning = value;
      notifyListeners();
    }));
    _globalSubs.add(FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    }, onError: (e) => debugPrint('Scan error: $e')));
  }

  @override
  void dispose() {
    for (final sub in _globalSubs) {
      sub.cancel();
    }
    for (final subs in _deviceSubs.values) {
      for (final sub in subs) {
        sub.cancel();
      }
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Getters used by the UI
  // ---------------------------------------------------------------------------

  bool get bluetoothOn => adapterState == BluetoothAdapterState.on;

  BluetoothDevice? get activeDevice =>
      activeDeviceId == null ? null : connected[activeDeviceId];

  bool? get activeLedState =>
      activeDeviceId == null ? null : ledState[activeDeviceId];

  bool hasLedControl(DeviceIdentifier id) => _ledChars.containsKey(id);

  /// Connected devices first, then everything found in the latest scan.
  List<NearbyDevice> get nearbyDevices {
    final Map<DeviceIdentifier, NearbyDevice> byId = {};
    for (final device in connected.values) {
      byId[device.remoteId] = NearbyDevice(device: device);
    }
    for (final r in _scanResults) {
      byId[r.device.remoteId] = NearbyDevice(device: r.device, rssi: r.rssi);
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        final ac = isConnected(a.device) ? 0 : 1;
        final bc = isConnected(b.device) ? 0 : 1;
        if (ac != bc) return ac - bc;
        return (b.rssi ?? -999).compareTo(a.rssi ?? -999);
      });
    return list;
  }

  bool isConnected(BluetoothDevice d) => connected.containsKey(d.remoteId);
  bool isConnecting(BluetoothDevice d) => connecting.contains(d.remoteId);

  static String displayName(BluetoothDevice d) {
    if (d.advName.isNotEmpty) return d.advName;
    if (d.platformName.isNotEmpty) return d.platformName;
    return 'Unknown device';
  }

  static String signalLabel(int? rssi) {
    if (rssi == null) return 'signal —';
    if (rssi >= -60) return 'signal strong';
    if (rssi >= -75) return 'signal good';
    return 'signal weak';
  }

  // ---------------------------------------------------------------------------
  // Scan
  // ---------------------------------------------------------------------------

  /// Returns an error message for the UI, or null when the scan started.
  Future<String?> startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      return 'Bluetooth LE is not supported on this device.';
    }

    if (!bluetoothOn) {
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {
          return 'Please turn on Bluetooth to scan for devices.';
        }
      } else {
        return 'Please turn on Bluetooth to scan for devices.';
      }
    }

    try {
      // Only devices that advertise our custom service show up,
      // so random headphones / watches around you are ignored.
      await FlutterBluePlus.startScan(
        withServices: [BleConfig.serviceUuid],
        timeout: BleConfig.scanTimeout,
      );
      return null;
    } catch (e) {
      debugPrint('startScan failed: $e');
      return 'Could not start scanning. Check Bluetooth permissions.';
    }
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  // ---------------------------------------------------------------------------
  // Connect / disconnect
  // ---------------------------------------------------------------------------

  /// Returns an error message for the UI, or null on success.
  Future<String?> connect(BluetoothDevice device) async {
    final id = device.remoteId;
    if (connected.containsKey(id) || connecting.contains(id)) return null;

    connecting.add(id);
    notifyListeners();

    try {
      if (isScanning) await FlutterBluePlus.stopScan();

      await device.connect(
        license: License.nonprofit, // personal / educational project
        timeout: BleConfig.connectTimeout,
      );

      // Keep the UI in sync if the ESP32 resets or goes out of range.
      final connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanup(id);
        }
      });
      _deviceSubs[id] = [connSub];

      connected[id] = device;
      activeDeviceId = id;
      await _setupLedCharacteristic(device);
      return null;
    } catch (e) {
      debugPrint('Connect failed: $e');
      await device.disconnect().catchError((_) {});
      _cleanup(id);
      return 'Failed to connect to ${displayName(device)}.';
    } finally {
      connecting.remove(id);
      notifyListeners();
    }
  }

  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      debugPrint('Disconnect failed: $e');
    }
    _cleanup(device.remoteId);
  }

  void setActiveDevice(DeviceIdentifier id) {
    if (!connected.containsKey(id)) return;
    activeDeviceId = id;
    notifyListeners();
  }

  void _cleanup(DeviceIdentifier id) {
    for (final sub in _deviceSubs.remove(id) ?? const <StreamSubscription>[]) {
      sub.cancel();
    }
    connected.remove(id);
    _ledChars.remove(id);
    ledState.remove(id);
    if (activeDeviceId == id) {
      activeDeviceId = connected.isEmpty ? null : connected.keys.first;
    }
    notifyListeners();
  }

  /// Finds the LED characteristic by UUID (not "any writable characteristic"),
  /// subscribes to state notifications, and reads the current LED state.
  Future<void> _setupLedCharacteristic(BluetoothDevice device) async {
    final id = device.remoteId;
    final services = await device.discoverServices();

    BluetoothCharacteristic? ledChar;
    for (final s in services) {
      if (s.uuid != BleConfig.serviceUuid) continue;
      for (final c in s.characteristics) {
        if (c.uuid == BleConfig.ledCharUuid) ledChar = c;
      }
    }

    if (ledChar == null) {
      debugPrint('LED characteristic not found on ${displayName(device)}');
      return;
    }
    _ledChars[id] = ledChar;

    if (ledChar.properties.notify) {
      final notifySub = ledChar.onValueReceived.listen((value) {
        _updateLedState(id, value);
      });
      _deviceSubs[id]?.add(notifySub);
      await ledChar.setNotifyValue(true);
    }

    if (ledChar.properties.read) {
      final value = await ledChar.read();
      _updateLedState(id, value);
    }
  }

  void _updateLedState(DeviceIdentifier id, List<int> value) {
    final text = utf8.decode(value, allowMalformed: true).trim().toUpperCase();
    if (text == BleConfig.commandOn || text == '1') {
      ledState[id] = true;
    } else if (text == BleConfig.commandOff || text == '0') {
      ledState[id] = false;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // LED control
  // ---------------------------------------------------------------------------

  /// Returns an error message for the UI, or null on success.
  Future<String?> setLed(bool on) async {
    final id = activeDeviceId;
    final char = id == null ? null : _ledChars[id];
    if (id == null || char == null) {
      return 'Connect a device first.';
    }

    final previous = ledState[id];
    ledState[id] = on; // optimistic update, confirmed by the ESP32 notification
    notifyListeners();

    try {
      final command = on ? BleConfig.commandOn : BleConfig.commandOff;
      await char.write(
        utf8.encode(command),
        withoutResponse: !char.properties.write && char.properties.writeWithoutResponse,
      );
      return null;
    } catch (e) {
      debugPrint('Write failed: $e');
      if (previous == null) {
        ledState.remove(id);
      } else {
        ledState[id] = previous;
      }
      notifyListeners();
      return 'Failed to send command to the device.';
    }
  }
}
