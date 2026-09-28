import 'dart:math';
import 'dart:ui';
import 'palette.dart';

void paintPassenger(Canvas c, double x, double y, double time) {
  c.save();
  c.translate(x, y);
  c.drawCircle(
    Offset.zero,
    24 + sin(time * 5) * 2,
    Paint()..color = Palette.mint.withValues(alpha: 0.13),
  );
  c.drawCircle(
    Offset.zero,
    20,
    Paint()
      ..color = Palette.mint.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
  c.drawOval(
    const Rect.fromLTWH(-10, 15, 24, 7),
    Paint()..color = const Color(0x44000000),
  );
  fillRound(c, const Rect.fromLTWH(-7, 7, 5, 11), Palette.ink, 2);
  fillRound(c, const Rect.fromLTWH(2, 7, 5, 11), Palette.ink, 2);
  fillRound(c, const Rect.fromLTWH(-10, -5, 20, 19), Palette.mint, 5);
  c.drawLine(
    const Offset(8, 0),
    Offset(17, -9 + sin(time * 7) * 3),
    Paint()
      ..color = Palette.mint
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round,
  );
  c.drawCircle(
    const Offset(0, -10),
    7,
    Paint()..color = const Color(0xFFE7B587),
  );
  c.drawArc(
    const Rect.fromLTWH(-7, -18, 14, 15),
    pi,
    pi,
    false,
    Paint()
      ..color = Palette.ink
      ..strokeWidth = 3,
  );
  c.restore();
}
