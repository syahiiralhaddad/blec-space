import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE contract shared with the ESP32 firmware
/// (see firmware/esp32_ble_led/esp32_ble_led.ino).
///
/// If you change any value here, change it in the firmware too.
class BleConfig {
  BleConfig._();

  /// Custom GATT service advertised by the ESP32.
  /// The app only lists devices that advertise this service.
  static final Guid serviceUuid = Guid('4fafc201-1fb5-459e-8fcc-c5c9c331914b');

  /// LED characteristic: write "ON" / "OFF", read or notify the current state.
  static final Guid ledCharUuid = Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8');

  static const String commandOn = 'ON';
  static const String commandOff = 'OFF';

  static const Duration scanTimeout = Duration(seconds: 8);
  static const Duration connectTimeout = Duration(seconds: 15);
}
