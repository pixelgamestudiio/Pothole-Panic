import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../game_state.dart';
import '../run_model.dart';
import 'palette.dart';

/// Original vector artwork: sharp at every device density, no missing sprites.
void paintRickshaw(
  Canvas canvas, {
  double scale = 1,
  double lean = 0,
  bool shield = false,
  double time = 0,
}) {
  canvas.save();
  canvas.scale(scale);
  canvas.rotate(lean);
  if (shield) {
    canvas.drawOval(
      const Rect.fromLTWH(-43, -60, 86, 124),
      Paint()..color = Palette.mint.withValues(alpha: 0.12),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-43, -60, 86, 124),
      Paint()
        ..color = Palette.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (int i = 0; i < 3; i++) {
      fillRound(
        canvas,
        Rect.fromLTWH(-17.0 + i * 14, 51, 5, 16 + sin(time * 28 + i) * 10),
        Palette.yellow,
        3,
      );
    }
  }
  canvas.drawOval(
    const Rect.fromLTWH(-32, -40, 70, 105),
    Paint()..color = const Color(0x50000000),
  );
  fillRound(
    canvas,
    const Rect.fromLTWH(-32, 17, 11, 26),
    const Color(0xFF111F1C),
    4,
  );
  fillRound(
    canvas,
    const Rect.fromLTWH(21, 17, 11, 26),
    const Color(0xFF111F1C),
    4,
  );
  fillRound(
    canvas,
    const Rect.fromLTWH(-7, -49, 14, 21),
    const Color(0xFF111F1C),
    5,
  );
  fillRound(canvas, const Rect.fromLTWH(-27, -29, 54, 75), Palette.yellow, 13);
  fillRound(
    canvas,
    const Rect.fromLTWH(-23, -38, 46, 34),
    const Color(0xFFEDB535),
    13,
  );
  fillRound(
    canvas,
    const Rect.fromLTWH(-20, -32, 40, 27),
    const Color(0xFF173D36),
    9,
  );
  final glass = Path()
    ..moveTo(-16, -28)
    ..lineTo(16, -28)
    ..lineTo(18, -10)
    ..lineTo(-18, -10)
    ..close();
  canvas.drawPath(glass, Paint()..color = const Color(0xFF7FB6AA));
  canvas.drawLine(
    const Offset(-13, -25),
    const Offset(9, -25),
    Paint()
      ..color = const Color(0xFFA8D7BC)
      ..strokeWidth = 3,
  );
  canvas.drawLine(
    const Offset(0, -28),
    const Offset(0, -10),
    Paint()
      ..color = const Color(0xFF173D36)
      ..strokeWidth = 2,
  );
  fillRound(
    canvas,
    const Rect.fromLTWH(-23, 0, 46, 36),
    const Color(0xFF13372D),
    7,
  );
  fillRound(
    canvas,
    const Rect.fromLTWH(-20, 3, 40, 28),
    const Color(0xFF205344),
    5,
  );
  canvas.drawLine(
    const Offset(-17, 7),
    const Offset(17, 7),
    Paint()
      ..color = const Color(0xFF39715D)
      ..strokeWidth = 2,
  );
  fillRound(canvas, const Rect.fromLTWH(-19, 39, 9, 4), Palette.orange, 1);
  fillRound(canvas, const Rect.fromLTWH(10, 39, 9, 4), Palette.orange, 1);
  fillRound(canvas, const Rect.fromLTWH(-7, 39, 14, 5), Palette.cream, 1);
  fillRound(canvas, const Rect.fromLTWH(-36, -17, 9, 6), Palette.yellow, 2);
  fillRound(canvas, const Rect.fromLTWH(27, -17, 9, 6), Palette.yellow, 2);
  canvas.drawCircle(const Offset(-15, -35), 4, Paint()..color = Palette.cream);
  canvas.drawCircle(const Offset(15, -35), 4, Paint()..color = Palette.cream);
  canvas.restore();
}

class AutoRickshaw extends Component {
  AutoRickshaw(this.model) : super(priority: 4);
  final RunModel model;
  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(
      model.playerX,
      GameConfig.playerY + sin(model.scroll * 0.06) * 1.2,
    );
    final dying =
        model.phase == GamePhase.dying || model.phase == GamePhase.gameOver;
    if (dying) {
      final t = (model.deathTime / 0.65).clamp(0.0, 1.0);
      canvas.rotate(t * pi * 2);
      canvas.scale(1 - t * 0.8);
    }
    final lean = (GameConfig.laneX(model.lane) - model.playerX) / 650;
    paintRickshaw(
      canvas,
      lean: lean,
      shield: model.shielded,
      time: model.elapsed,
    );
    canvas.restore();
  }
}
