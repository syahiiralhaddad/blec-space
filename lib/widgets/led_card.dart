import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// "Switch LED" card: glowing bulb + ON/OFF segmented toggle.
class LedCard extends StatelessWidget {
  const LedCard({
    super.key,
    required this.deviceName,
    required this.isOn,
    required this.enabled,
    required this.onChanged,
  });

  final String? deviceName;
  final bool? isOn; // null = unknown
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final on = isOn ?? false;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Switch LED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      deviceName == null ? 'Connect a device to control its LED' : 'Controlling $deviceName',
                      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (enabled && isOn != null)
                StatusPill(
                  label: on ? 'On' : 'Off',
                  background: on ? AppColors.amberSoft : AppColors.iconBg,
                  foreground: on ? AppColors.amberText : AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 28),
          _Bulb(on: enabled && on),
          const SizedBox(height: 28),
          _OnOffToggle(
            value: on,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Bulb extends StatelessWidget {
  const _Bulb({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? const Color(0xFFFFF7E8) : const Color(0xFFF5F6F8),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? const Color(0xFFFFEBC7) : const Color(0xFFECEEF2),
            boxShadow: on
                ? const [BoxShadow(color: Color(0x55F5A623), blurRadius: 40, spreadRadius: 4)]
                : const [],
          ),
          child: Icon(
            on ? Icons.lightbulb : Icons.lightbulb_outline,
            size: 72,
            color: on ? AppColors.amber : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

class _OnOffToggle extends StatelessWidget {
  const _OnOffToggle({required this.value, required this.enabled, required this.onChanged});

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, bool segmentValue) {
      final selected = enabled && value == segmentValue;
      return Expanded(
        child: GestureDetector(
          onTap: enabled ? () => onChanged(segmentValue) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : enabled
                        ? AppColors.textSecondary
                        : const Color(0xFFC0C4CC),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [segment('ON', true), segment('OFF', false)]),
    );
  }
}
