import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geoattend/core/core.dart';

/// Ring chart with a centred percentage (HOD daily summary, admin overview).
class DonutProgress extends StatelessWidget {
  const DonutProgress({super.key, required this.percent, this.size = 120});
  final int percent; // 0..100
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(percent.clamp(0, 100) / 100),
        child: Center(child: Text('$percent%', style: TextStyle(fontSize: size / 5.5))),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..color = AppColors.lavender
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final arc = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.value != value;
}
