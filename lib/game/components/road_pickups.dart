import 'dart:math';
import 'dart:ui';
import '../game_state.dart';
import 'palette.dart';

void paintRoadPickup(Canvas c, RoadItem item, double x, double time) {
  c.save();
  c.translate(x, item.y);
  switch (item.kind) {
    case ItemKind.coin:
      c.drawCircle(
        Offset.zero,
        23 + sin(time * 5) * 2,
        Paint()..color = Palette.yellow.withValues(alpha: 0.16),
      );
      c.drawCircle(Offset.zero, 14, Paint()..color = const Color(0xFFB37622));
      c.drawCircle(const Offset(0, -2), 13, Paint()..color = Palette.yellow);
      c.drawCircle(
        const Offset(0, -2),
        9,
        Paint()
          ..color = const Color(0xFFDB9B31)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      drawLabel(c, '5', const Offset(0, -2), size: 13, color: Palette.ink);
    case ItemKind.barricade:
      for (final x in [-23.0, 17.0]) {
        fillRound(c, Rect.fromLTWH(x, -14, 6, 34), Palette.cream, 2);
        fillRound(c, Rect.fromLTWH(x - 3, 16, 12, 5), Palette.ink, 1);
      }
      fillRound(c, const Rect.fromLTWH(-32, -15, 64, 21), Palette.orange, 3);
      c.save();
      c.clipRect(const Rect.fromLTWH(-31, -14, 62, 19));
      for (var i = -2; i < 4; i++) {
        final x = i * 22.0;
        final stripe = Path()
          ..moveTo(x, -15)
          ..lineTo(x + 10, -15)
          ..lineTo(x - 4, 7)
          ..lineTo(x - 14, 7)
          ..close();
        c.drawPath(stripe, Paint()..color = Palette.ink);
      }
      c.restore();
      c.drawCircle(const Offset(-25, -21), 4, Paint()..color = Palette.yellow);
      c.drawCircle(const Offset(25, -21), 4, Paint()..color = Palette.yellow);
    case ItemKind.oil:
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: item.radius * 2.3,
          height: item.radius * 1.3,
        ),
        Paint()..color = const Color(0xFF172331),
      );
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(-8, -3),
          width: item.radius,
          height: item.radius * 0.8,
        ),
        Paint()..color = const Color(0xFF443D68),
      );
      c.drawArc(
        Rect.fromLTWH(-19, -10, 37, 18),
        0.1,
        2.5,
        false,
        Paint()
          ..color = const Color(0xFF6EB7BA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      drawLabel(c, 'OIL', const Offset(0, 30), size: 10, color: Palette.mint);
    case ItemKind.pothole:
    case ItemKind.passenger:
      break;
  }
  c.restore();
}
