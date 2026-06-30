import 'package:flutter/material.dart';

/// Multicolor Google "G" mark for sign-in buttons.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = _blue;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.958, h * 0.502)
        ..cubicTo(w * 0.958, h * 0.471, w * 0.956, h * 0.44, w * 0.952, h * 0.41)
        ..lineTo(w * 0.502, h * 0.41)
        ..lineTo(w * 0.502, h * 0.59)
        ..lineTo(w * 0.738, h * 0.59)
        ..cubicTo(w * 0.728, h * 0.674, w * 0.678, h * 0.748, w * 0.602, h * 0.798)
        ..lineTo(w * 0.602, h * 0.928)
        ..lineTo(w * 0.742, h * 0.928)
        ..cubicTo(w * 0.87, h * 0.854, w * 0.958, h * 0.69, w * 0.958, h * 0.502)
        ..close(),
      paint,
    );

    paint.color = _green;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.242, h * 0.716)
        ..cubicTo(w * 0.218, h * 0.654, w * 0.204, h * 0.586, w * 0.204, h * 0.512)
        ..cubicTo(w * 0.204, h * 0.438, w * 0.218, h * 0.37, w * 0.242, h * 0.308)
        ..lineTo(w * 0.102, h * 0.198)
        ..cubicTo(w * 0.046, h * 0.32, w * 0.01, h * 0.412, w * 0.01, h * 0.512)
        ..cubicTo(w * 0.01, h * 0.612, w * 0.046, h * 0.704, w * 0.102, h * 0.826)
        ..lineTo(w * 0.242, h * 0.716)
        ..close(),
      paint,
    );

    paint.color = _yellow;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.502, h * 0.204)
        ..cubicTo(w * 0.584, h * 0.204, w * 0.658, h * 0.232, w * 0.716, h * 0.278)
        ..lineTo(w * 0.852, h * 0.142)
        ..cubicTo(w * 0.756, h * 0.054, w * 0.636, h * 0.002, w * 0.502, h * 0.002)
        ..cubicTo(w * 0.316, h * 0.002, w * 0.156, h * 0.094, w * 0.066, h * 0.234)
        ..lineTo(w * 0.206, h * 0.344)
        ..cubicTo(w * 0.282, h * 0.224, w * 0.382, h * 0.204, w * 0.502, h * 0.204)
        ..close(),
      paint,
    );

    paint.color = _red;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.502, h * 0.998)
        ..cubicTo(w * 0.628, h * 0.998, w * 0.742, h * 0.952, w * 0.832, h * 0.874)
        ..lineTo(w * 0.694, h * 0.762)
        ..cubicTo(w * 0.644, h * 0.798, w * 0.578, h * 0.82, w * 0.502, h * 0.82)
        ..cubicTo(w * 0.382, h * 0.82, w * 0.282, h * 0.744, w * 0.206, h * 0.624)
        ..lineTo(w * 0.066, h * 0.734)
        ..cubicTo(w * 0.156, h * 0.874, w * 0.316, h * 0.998, w * 0.502, h * 0.998)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
