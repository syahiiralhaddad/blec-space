import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/dashed_border.dart';
import '../widgets/device_tile.dart';
import 'connect_device_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openConnect(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConnectDeviceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = BleService.instance;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: ListenableBuilder(
            listenable: ble,
            builder: (context, _) {
              final devices = ble.connected.values.toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BrandTitle(),
                      const Spacer(),
                      SquareIconButton(
                        icon: Icons.tune,
                        tooltip: 'Settings',
                        onTap: () => _showSettings(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _ConnectBanner(),
                  const SizedBox(height: 28),
                  SectionHeader(
                    title: 'Your devices',
                    trailing: '${devices.length} connected',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: devices.isEmpty
                        ? const _EmptyDevices()
                        : Align(
                            alignment: Alignment.topCenter,
                            child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: devices.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (context, i) {
                                final d = devices[i];
                                final led = ble.ledState[d.remoteId];
                                return DeviceTile(
                                  name: BleService.displayName(d),
                                  subtitle: led == null
                                      ? 'Connected'
                                      : 'Connected · LED ${led ? 'on' : 'off'}',
                                  status: DeviceTileStatus.connected,
                                  onTap: () {
                                    ble.setActiveDevice(d.remoteId);
                                    _openConnect(context);
                                  },
                                );
                              },
                            ),
                          ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Add Device',
                    leadingIcon: Icons.add,
                    onPressed: () => _openConnect(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final ble = BleService.instance;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ListenableBuilder(
            listenable: ble,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    ble.bluetoothOn ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: ble.bluetoothOn ? AppColors.primary : AppColors.danger,
                  ),
                  title: const Text('Bluetooth'),
                  subtitle: Text(ble.bluetoothOn ? 'On' : 'Off — turn it on to scan'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: ble.connected.isNotEmpty,
                  leading: const Icon(Icons.link_off),
                  title: const Text('Disconnect all devices'),
                  onTap: () async {
                    for (final d in ble.connected.values.toList()) {
                      await ble.disconnect(d);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectBanner extends StatelessWidget {
  const _ConnectBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Let's Connect!",
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Pair a BLE device to start controlling your project.',
                  style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.bluetooth, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.bluetooth, color: AppColors.primary, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'No devices connected yet',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Make sure your device is powered on and Bluetooth is enabled, then add it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
