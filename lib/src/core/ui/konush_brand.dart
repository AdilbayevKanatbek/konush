import 'package:flutter/material.dart';

const konushBrandColor = Color(0xFF0E7A6E);
const konushBrandAccent = Color(0xFFF4B544);

/// Rounded lowercase K, shared by the wordmark and generated launcher assets.
/// Coordinates are independent of fonts and retain their shape at small sizes.
void paintKonushSymbol(
  Canvas canvas,
  Size size, {
  Color color = konushBrandColor,
  Color accent = konushBrandAccent,
}) {
  canvas.save();
  canvas.scale(size.width / 32, size.height / 32);
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawLine(const Offset(7, 5.5), const Offset(7, 26), stroke);
  canvas.drawPath(
    Path()
      ..moveTo(7, 18)
      ..cubicTo(13, 18, 17, 15, 22, 10.5),
    stroke,
  );
  canvas.drawPath(
    Path()
      ..moveTo(12, 17)
      ..cubicTo(17, 18, 19, 23, 24, 26),
    stroke,
  );
  canvas.drawCircle(const Offset(25, 4), 2.8, Paint()..color = accent);
  canvas.restore();
}

class KonushSymbolPainter extends CustomPainter {
  const KonushSymbolPainter();

  @override
  void paint(Canvas canvas, Size size) => paintKonushSymbol(canvas, size);

  @override
  bool shouldRepaint(KonushSymbolPainter oldDelegate) => false;
}
