import 'dart:math';
import 'dart:ui';
import 'palette.dart';

void paintPothole(Canvas c, double x, double y, double radius, int variant) {
  c.save();
  c.translate(x, y);
  final path = Path();
  for (int i = 0; i < 12; i++) {
    final a = i / 12 * pi * 2;
    final r = radius * (i.isEven ? 1.12 : 0.95);
    final px = cos(a) * r, py = sin(a) * r * 0.66;
    if (i == 0) {
      path.moveTo(px, py);
    } else {
      path.lineTo(px, py);
    }
  }
  path.close();
  c.drawPath(path, Paint()..color = const Color(0xFF242C29));
  c.drawPath(
    path,
    Paint()
      ..color = const Color(0xFF8B8772)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );
  c.drawOval(
    Rect.fromCenter(
      center: const Offset(0, 2),
      width: radius * 1.5,
      height: radius * 0.8,
    ),
    Paint()..color = const Color(0xFF151F20),
  );
  c.drawArc(
    Rect.fromCenter(
      center: const Offset(0, 4),
      width: radius * 1.25,
      height: radius * 0.55,
    ),
    0.3,
    2.6,
    false,
    Paint()
      ..color = const Color(0xFF506368)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  for (int i = 0; i < 3; i++) {
    final a = i * 2.1 + variant;
    c.drawLine(
      Offset(cos(a) * radius, sin(a) * radius * 0.7),
      Offset(cos(a) * (radius + 9), sin(a) * (radius + 9) * 0.7),
      Paint()
        ..color = const Color(0xFF252D27)
        ..strokeWidth = 2,
    );
  }
  fillRound(c, Rect.fromLTWH(-radius - 5, 5, 6, 4), const Color(0xFF8B8772), 1);
  c.restore();
}
