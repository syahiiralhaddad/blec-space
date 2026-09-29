import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

enum DeviceTileStatus { available, connecting, connected }

/// One device row: chip icon, name + subtitle, and a status/action on the right.
class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    this.onConnect,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final String name;
  final String subtitle;
  final DeviceTileStatus status;
  final VoidCallback? onConnect;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : AppColors.iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.memory,
                color: selected ? AppColors.primary : AppColors.textPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _trailing(),
          ],
        ),
      ),
    );
  }

  Widget _trailing() {
    return switch (status) {
      DeviceTileStatus.connected => const StatusPill(
          label: 'Connected',
          background: AppColors.successSoft,
          foreground: AppColors.success,
        ),
      DeviceTileStatus.connecting => const SizedBox(
          width: 110,
          height: 44,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      DeviceTileStatus.available => SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onConnect,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: const Text('Connect'),
          ),
        ),
    };
  }
}
