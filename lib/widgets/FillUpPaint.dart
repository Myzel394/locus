import 'package:flutter/material.dart';

class FillUpPainter extends CustomPainter {
  final double fillPercentage;
  final Color color;

  const FillUpPainter({
    required this.fillPercentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect =
        Rect.fromLTWH(0, (size.height - size.height * fillPercentage), size.width, size.height * fillPercentage);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FillUpPaint extends StatelessWidget {
  final double fillPercentage;
  final Color color;
  final Size size;
  final Widget? child;

  const FillUpPaint({
    required this.fillPercentage,
    required this.color,
    required this.size,
    this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FillUpPainter(
        fillPercentage: fillPercentage,
        color: color,
      ),
      size: size,
      child: child,
    );
  }
}
