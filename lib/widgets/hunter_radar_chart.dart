import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

const List<String> kHunterStatKeys = <String>[
  'presence',
  'strength',
  'agility',
  'endurance',
  'intelligence',
  'discipline',
];

String hunterStatLabel(String key) {
  switch (key) {
    case 'presence':
      return 'PRESENCE';
    case 'strength':
      return 'STRENGTH';
    case 'agility':
      return 'AGILITY';
    case 'endurance':
      return 'ENDURANCE';
    case 'intelligence':
      return 'INTELLIGENCE';
    case 'discipline':
      return 'DISCIPLINE';
    default:
      return key.toUpperCase();
  }
}

class HunterRadarChart extends StatelessWidget {
  final Map<String, int> stats;
  final double size;
  final int maxValue;

  const HunterRadarChart({
    required this.stats,
    this.size = 170,
    this.maxValue = 99,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final clampedMax = max(1, maxValue);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          values: kHunterStatKeys
              .map((k) => (stats[k] ?? 0).clamp(0, clampedMax).toDouble())
              .toList(growable: false),
          maxValue: clampedMax.toDouble(),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;

  _RadarPainter({
    required this.values,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final axisCount = max(3, values.length);

    final gridPaint = Paint()
      ..color = AppColors.dividerColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppColors.dividerColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = AppColors.neonBlue.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.neonBlue.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Grid rings (3)
    const rings = 3;
    for (int r = 1; r <= rings; r++) {
      final rr = radius * (r / rings);
      final path = Path();
      for (int i = 0; i < axisCount; i++) {
        final angle = _angleForIndex(i, axisCount);
        final p = center + Offset(cos(angle), sin(angle)) * rr;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axis lines
    for (int i = 0; i < axisCount; i++) {
      final angle = _angleForIndex(i, axisCount);
      final end = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawLine(center, end, axisPaint);
    }

    // Values polygon
    final poly = Path();
    for (int i = 0; i < axisCount; i++) {
      final v = i < values.length ? values[i] : 0.0;
      final t = (v / maxValue).clamp(0.0, 1.0);
      final angle = _angleForIndex(i, axisCount);
      final p = center + Offset(cos(angle), sin(angle)) * (radius * t);
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
    }
    poly.close();

    canvas.drawPath(poly, fillPaint);
    canvas.drawPath(poly, strokePaint);

    // Center dot
    canvas.drawCircle(
      center,
      2.5,
      Paint()..color = AppColors.neonBlue.withValues(alpha: 0.8),
    );
  }

  double _angleForIndex(int index, int count) {
    // Start at -90° (top), evenly spaced clockwise.
    final step = (2 * pi) / count;
    return (-pi / 2) + (index * step);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter other) {
    if (other.maxValue != maxValue) return true;
    if (other.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (other.values[i] != values[i]) return true;
    }
    return false;
  }
}
