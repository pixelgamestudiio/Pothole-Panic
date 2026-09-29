import 'dart:ui';
import '../vehicle.dart';
import 'auto_rickshaw.dart';
import 'palette.dart';

void paintVehicle(
  Canvas c,
  Vehicle vehicle, {
  double scale = 1,
  double lean = 0,
  bool shield = false,
  double time = 0,
}) {
  if (vehicle == Vehicle.auto) {
    paintRickshaw(c, scale: scale, lean: lean, shield: shield, time: time);
    return;
  }
  c.save();
  c.scale(scale);
  c.rotate(lean);
  if (shield) {
    c.drawOval(
      const Rect.fromLTWH(-43, -60, 86, 124),
      Paint()
        ..color = Palette.mint.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
  c.drawOval(
    const Rect.fromLTWH(-30, -42, 66, 104),
    Paint()..color = const Color(0x55000000),
  );
  if (vehicle == Vehicle.car) {
    for (final x in [-33.0, 24.0]) {
      for (final y in [-29.0, 23.0]) {
        fillRound(c, Rect.fromLTWH(x, y, 9, 22), Palette.ink, 3);
      }
    }
    fillRound(
      c,
      const Rect.fromLTWH(-29, -48, 58, 98),
      const Color(0xFFDF634B),
      17,
    );
    fillRound(c, const Rect.fromLTWH(-24, -42, 48, 23), Palette.orange, 10);
    fillRound(c, const Rect.fromLTWH(-23, -18, 46, 52), Palette.ink, 10);
    fillRound(
      c,
      const Rect.fromLTWH(-20, -15, 40, 15),
      const Color(0xFF9CCECB),
      5,
    );
    fillRound(
      c,
      const Rect.fromLTWH(-19, 3, 38, 22),
      const Color(0xFFD75543),
      6,
    );
    fillRound(
      c,
      const Rect.fromLTWH(-18, 28, 36, 9),
      const Color(0xFF759E9C),
      3,
    );
    for (final x in [-24.0, 14.0]) {
      fillRound(c, Rect.fromLTWH(x, -43, 10, 5), Palette.cream, 2);
      fillRound(c, Rect.fromLTWH(x, 43, 10, 4), const Color(0xFFFFC05A), 2);
    }
    fillRound(c, const Rect.fromLTWH(-37, -10, 8, 6), Palette.orange, 2);
    fillRound(c, const Rect.fromLTWH(29, -10, 8, 6), Palette.orange, 2);
  } else {
    fillRound(c, const Rect.fromLTWH(-6, -49, 12, 24), Palette.ink, 5);
    fillRound(c, const Rect.fromLTWH(-7, 29, 14, 25), Palette.ink, 5);
    fillRound(
      c,
      const Rect.fromLTWH(-12, -25, 24, 65),
      const Color(0xFF4DADA5),
      10,
    );
    fillRound(c, const Rect.fromLTWH(-8, -38, 16, 14), Palette.mint, 6);
    fillRound(c, const Rect.fromLTWH(-7, 15, 14, 22), Palette.ink, 4);
    c.drawLine(
      const Offset(-24, -25),
      const Offset(24, -25),
      Paint()
        ..color = Palette.cream
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    for (final x in [-15.0, 10.0]) {
      fillRound(c, Rect.fromLTWH(x, 4, 6, 20), Palette.ink, 3);
    }
    fillRound(c, const Rect.fromLTWH(-15, -15, 30, 30), Palette.yellow, 12);
    c.drawCircle(const Offset(0, -15), 12, Paint()..color = Palette.cream);
    fillRound(c, const Rect.fromLTWH(-9, -24, 18, 8), Palette.ink, 4);
    fillRound(c, const Rect.fromLTWH(-5, -37, 10, 4), Palette.cream, 2);
    fillRound(c, const Rect.fromLTWH(-5, 38, 10, 4), Palette.orange, 2);
  }
  c.restore();
}
