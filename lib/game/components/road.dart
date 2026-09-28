import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../run_model.dart';
import 'palette.dart';

class Road extends Component {
  Road(this.model);
  final RunModel model;
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 420, 800),
      Paint()..color = const Color(0xFFB7AD83),
    );
    canvas.drawRect(
      const Rect.fromLTWH(61, 0, 298, 800),
      Paint()..color = Palette.asphalt,
    );
    canvas.drawRect(
      const Rect.fromLTWH(68, 0, 284, 800),
      Paint()..color = const Color(0xFF494E47),
    );
    // Asphalt grain and patched seams are deterministic, not randomized per frame.
    final offset = model.scroll % 160;
    final p = Paint()
      ..color = const Color(0x184E6658)
      ..strokeWidth = 1;
    for (int row = -1; row < 7; row++) {
      for (int j = 0; j < 14; j++) {
        final x = 73 + (j * 47 + row.abs() * 19) % 273;
        final y = row * 160 + offset + (j * 29) % 150;
        canvas.drawLine(Offset(x.toDouble(), y), Offset(x + 5.0, y + 2), p);
      }
    }
    for (int i = -1; i < 15; i++) {
      final y = i * 64 + model.scroll % 64;
      for (final x in [57.0, 357.0]) {
        fillRound(canvas, Rect.fromLTWH(x, y, 6, 32), Palette.cream, 0);
        fillRound(canvas, Rect.fromLTWH(x, y + 32, 6, 32), Palette.ink, 0);
      }
    }
    final stripe = Paint()..color = const Color(0x77FFF1CD);
    for (int i = -1; i < 10; i++) {
      final y = i * 105 + model.scroll % 105;
      for (final x in [161.0, 257.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 2, 42),
            const Radius.circular(1),
          ),
          stripe,
        );
      }
    }
    for (int i = -1; i < 5; i++) {
      final y = i * 245 + model.scroll * 0.8 % 245;
      _shop(canvas, -22, y - 25, i.isEven);
      _tree(canvas, 389, y + 123);
      _tree(canvas, 26, y + 160);
      _shop(canvas, 369, y - 55, i.isOdd);
    }
    // Light, long shadows from the roadside.
    canvas.drawRect(
      const Rect.fromLTWH(64, 0, 7, 800),
      Paint()..color = const Color(0x22000000),
    );
  }

  void _tree(Canvas c, double x, double y) {
    c.drawOval(
      Rect.fromCenter(center: Offset(x + 7, y + 12), width: 52, height: 58),
      Paint()..color = const Color(0x260F3026),
    );
    fillRound(c, Rect.fromLTWH(x - 3, y, 6, 35), const Color(0xFF71583B), 2);
    for (int k = 0; k < 5; k++) {
      c.drawCircle(
        Offset(x + cos(k * 1.3) * 12, y + sin(k * 1.3) * 12),
        18,
        Paint()
          ..color = k.isEven
              ? const Color(0xFF527D50)
              : const Color(0xFF638B55),
      );
    }
    c.drawCircle(
      Offset(x - 5, y - 7),
      15,
      Paint()..color = const Color(0xFF7A9A5C),
    );
  }

  void _shop(Canvas c, double x, double y, bool blue) {
    fillRound(
      c,
      Rect.fromLTWH(x + 4, y + 6, 67, 102),
      const Color(0x28000000),
      2,
    );
    fillRound(
      c,
      Rect.fromLTWH(x, y, 64, 99),
      blue ? const Color(0xFF56877B) : const Color(0xFFC47B59),
      3,
    );
    fillRound(
      c,
      Rect.fromLTWH(x + 5, y + 5, 54, 70),
      blue ? const Color(0xFF71A397) : const Color(0xFFD59A6E),
      2,
    );
    for (int k = 0; k < 6; k++) {
      fillRound(
        c,
        Rect.fromLTWH(x + k * 10.5, y + 80, 10.5, 19),
        k.isEven
            ? Palette.cream
            : (blue ? const Color(0xFF467565) : Palette.orange),
        0,
      );
    }
    fillRound(
      c,
      Rect.fromLTWH(x + 19, y + 18, 24, 23),
      const Color(0x330F3026),
      2,
    );
  }
}
