import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Illustration on the welcome screen: Bluetooth hub in the middle, orbit rings,
/// and three "things" (board, bulb, sensor) connected with dashed lines.
class BluetoothHero extends StatelessWidget {
  const BluetoothHero({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE4EAFD),
          borderRadius: BorderRadius.circular(32),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final size = c.maxWidth;
            final center = Offset(size / 2, size / 2);
            // satellites: (angle in degrees, radius factor)
            final satellites = <_Satellite>[
              _Satellite(-145, 0.30, Icons.developer_board_outlined, AppColors.textPrimary),
              _Satellite(-25, 0.34, Icons.lightbulb, AppColors.amber),
              _Satellite(70, 0.33, Icons.monitor_heart_outlined, AppColors.primary),
            ];
            final bubble = size * 0.17;
            final hub = size * 0.23;

            Offset pos(_Satellite s) {
              final a = s.angle * math.pi / 180;
              return center + Offset(math.cos(a), math.sin(a)) * (size * s.radius);
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitPainter(
                      center: center,
                      targets: satellites.map(pos).toList(),
                    ),
                  ),
                ),
                Positioned(
                  left: center.dx - hub / 2,
                  top: center.dy - hub / 2,
                  child: Container(
                    width: hub,
                    height: hub,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(hub * 0.28),
                    ),
                    child: Icon(Icons.bluetooth, color: Colors.white, size: hub * 0.62),
                  ),
                ),
                for (final s in satellites)
                  Positioned(
                    left: pos(s).dx - bubble / 2,
                    top: pos(s).dy - bubble / 2,
                    child: Container(
                      width: bubble,
                      height: bubble,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12)],
                      ),
                      child: Icon(s.icon, color: s.color, size: bubble * 0.45),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Satellite {
  _Satellite(this.angle, this.radius, this.icon, this.color);
  final double angle;
  final double radius;
  final IconData icon;
  final Color color;
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.center, required this.targets});

  final Offset center;
  final List<Offset> targets;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = const Color(0xFFC7D3FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, size.width * 0.46, ring);
    canvas.drawCircle(center, size.width * 0.34, ring..strokeWidth = 2);

    final dashed = Paint()
      ..color = const Color(0xFF9DB1F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // dashed inner orbit
    const dashes = 36;
    final r = size.width * 0.22;
    for (var i = 0; i < dashes; i++) {
      final start = i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start,
        (2 * math.pi / dashes) * 0.55,
        false,
        dashed,
      );
    }

    // dashed lines from hub to each satellite
    for (final t in targets) {
      final total = (t - center).distance;
      final dir = (t - center) / total;
      double d = size.width * 0.12;
      while (d < total - size.width * 0.08) {
        final end = math.min(d + 5, total);
        canvas.drawLine(center + dir * d, center + dir * end, dashed);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.center != center;
}
