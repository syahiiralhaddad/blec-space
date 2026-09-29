import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/device_tile.dart';
import '../widgets/led_card.dart';

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final ble = BleService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    ble.stopScan();
    super.dispose();
  }

  Future<void> _scan() async {
    final error = await ble.startScan();
    if (error != null && mounted) showAppSnackBar(context, error);
  }

  Future<void> _connect(NearbyDevice item) async {
    final error = await ble.connect(item.device);
    if (!mounted) return;
    showAppSnackBar(
      context,
      error ?? 'Connected to ${BleService.displayName(item.device)}',
    );
  }

  Future<void> _setLed(bool on) async {
    final error = await ble.setLed(on);
    if (error != null && mounted) showAppSnackBar(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: ble,
          builder: (context, _) {
            final nearby = ble.nearbyDevices;
            final active = ble.activeDevice;

            return RefreshIndicator(
              onRefresh: _scan,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Row(
                    children: [
                      SquareIconButton(
                        icon: Icons.arrow_back,
                        tooltip: 'Back',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Connect Device',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                      ),
                      GestureDetector(
                        onTap: ble.isScanning ? null : _scan,
                        child: StatusPill(
                          label: ble.isScanning ? 'Scanning' : 'Scan again',
                          background: AppColors.primarySoft,
                          foreground: AppColors.primary,
                          showDot: ble.isScanning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SectionHeader(title: 'Nearby devices', trailing: '${nearby.length} found'),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: nearby.isEmpty
                        ? _NoDevicesFound(scanning: ble.isScanning, bluetoothOn: ble.bluetoothOn)
                        : Column(
                            children: [
                              for (var i = 0; i < nearby.length; i++) ...[
                                if (i > 0) const Divider(height: 1, color: AppColors.border),
                                _tileFor(nearby[i]),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  LedCard(
                    deviceName: active == null ? null : BleService.displayName(active),
                    isOn: ble.activeLedState,
                    enabled: active != null && ble.hasLedControl(active.remoteId),
                    onChanged: _setLed,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tileFor(NearbyDevice item) {
    final d = item.device;
    final connected = ble.isConnected(d);
    final connecting = ble.isConnecting(d);
    final signal = BleService.signalLabel(item.rssi);

    return DeviceTile(
      name: BleService.displayName(d),
      subtitle: connected
          ? 'Connected${item.rssi != null ? ' · $signal' : ''}'
          : 'Available · tap to pair',
      status: connected
          ? DeviceTileStatus.connected
          : connecting
              ? DeviceTileStatus.connecting
              : DeviceTileStatus.available,
      selected: connected && ble.activeDeviceId == d.remoteId,
      onConnect: () => _connect(item),
      // Tap a connected device to control it, or long-press to disconnect.
      onTap: connected ? () => ble.setActiveDevice(d.remoteId) : () => _connect(item),
      onLongPress: connected ? () => _confirmDisconnect(item) : null,
    );
  }

  Future<void> _confirmDisconnect(NearbyDevice item) async {
    final name = BleService.displayName(item.device);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Disconnect')),
        ],
      ),
    );
    if (ok == true) {
      await ble.disconnect(item.device);
      if (mounted) showAppSnackBar(context, 'Disconnected from $name');
    }
  }
}

class _NoDevicesFound extends StatelessWidget {
  const _NoDevicesFound({required this.scanning, required this.bluetoothOn});

  final bool scanning;
  final bool bluetoothOn;

  @override
  Widget build(BuildContext context) {
    final String message;
    if (!bluetoothOn) {
      message = 'Bluetooth is off. Turn it on, then pull down to scan again.';
    } else if (scanning) {
      message = 'Looking for nearby ESP32 devices…';
    } else {
      message = 'No devices found. Make sure the ESP32 is powered on, then pull down to scan again.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          if (scanning)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          else
            const Icon(Icons.bluetooth_searching, color: AppColors.textSecondary, size: 32),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
