import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../game_state.dart';
import '../road_environment.dart';
import '../run_model.dart';
import '../vehicle.dart';

/// Grade the environment below hazards, so even at night every obstacle stays
/// readable. Headlights add atmosphere without hiding hazards outside a beam.
class RoadLighting extends Component {
  RoadLighting(this.model) : super(priority: 1);
  final RunModel model;
  @override
  void render(Canvas canvas) {
    final c = canvas;
    final light = model.daylight;
    Color grade(Daylight value) => switch (value) {
      Daylight.day => const Color(0x00FFFFFF),
      Daylight.afternoon => const Color(0x30DB8D48),
      Daylight.night => const Color(0x9909142C),
    };
    final color = Color.lerp(
      grade(light),
      grade(model.nextDaylight),
      model.lightBlend,
    )!;
    c.drawRect(const Rect.fromLTWH(0, 0, 420, 800), Paint()..color = color);
    if (model.rain > 0) {
      c.drawRect(
        const Rect.fromLTWH(0, 0, 420, 800),
        Paint()
          ..color = const Color(0xFF44677B).withValues(alpha: model.rain * .12),
      );
    }
    final night = model.lightWeight(Daylight.night);
    if (night <= 0) return;
    final lamps = model.vehicle == Vehicle.bike ? [0.0] : [-16.0, 16.0];
    for (final offset in lamps) {
      final x = model.playerX + offset;
      final beam = Path()
        ..moveTo(x - 4, GameConfig.playerY - 33)
        ..lineTo(x - 95, GameConfig.playerY - 330)
        ..quadraticBezierTo(
          x,
          GameConfig.playerY - 390,
          x + 95,
          GameConfig.playerY - 330,
        )
        ..lineTo(x + 4, GameConfig.playerY - 33)
        ..close();
      c.drawPath(
        beam,
        Paint()
          ..shader = Gradient.linear(
            Offset(x, GameConfig.playerY - 35),
            Offset(x, GameConfig.playerY - 370),
            [
              const Color(0xFFFFF2CA).withValues(alpha: .216 * night),
              const Color(0x00FFF2CA),
            ],
          ),
      );
    }
    // Low-contrast edge vignette leaves all three playable lanes visible.
    c.drawRect(
      const Rect.fromLTWH(0, 0, 420, 800),
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          const Offset(420, 0),
          [
            const Color(0xFF051220).withValues(alpha: .25 * night),
            const Color(0x00051220),
            const Color(0x00051220),
            const Color(0xFF051220).withValues(alpha: .25 * night),
          ],
          [0, .2, .8, 1],
        ),
    );
  }
}

class Weather extends Component {
  Weather(this.model) : super(priority: 6);
  final RunModel model;

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final rain = model.rain;
    if (rain <= 0) return;
    final time = model.elapsed;
    // Two sparse depth layers, variable wind/length and irregular positions.
    // This is precipitation, not a uniform full-screen diagonal hatch pattern.
    for (int layer = 0; layer < 2; layer++) {
      final count = layer == 0 ? 42 : 22;
      for (int i = 0; i < count; i++) {
        final n = sceneryNoise(i, layer + 210);
        final fall = (layer == 0 ? 230 : 420) + n * 130;
        final wind = 10 + sin(time * .15) * 12;
        final x = (sceneryNoise(i, 321 + layer) * 460 + time * wind) % 460 - 20;
        final y = (sceneryNoise(i, 426 + layer) * 900 + time * fall) % 900 - 50;
        final length = (layer == 0 ? 4 : 10) + n * 8;
        c.drawLine(
          Offset(x, y),
          Offset(x - wind * .09, y + length),
          Paint()
            ..color = const Color(
              0xFFD5E9EB,
            ).withValues(alpha: rain * (layer == 0 ? .15 : .31))
            ..strokeWidth = layer == 0 ? .6 : 1.1
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    // Small impact rings are fixed to the road until the ripple fades.
    for (int i = 0; i < 16; i++) {
      final cycle = time * 1.7 + sceneryNoise(i, 503) * 6;
      final pulse = cycle % 1;
      final x = 78 + sceneryNoise(i + cycle.floor(), 615) * 264;
      final y = (sceneryNoise(i, 720) * 800 + model.scroll) % 800;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 2 + pulse * 13,
          height: 1 + pulse * 5,
        ),
        Paint()
          ..color = const Color(
            0xFFA6C3C9,
          ).withValues(alpha: rain * (1 - pulse) * .19)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
    }
    // Shallow roadside water reflects warm street lighting after dark.
    final world = model.scroll + GameConfig.playerY;
    for (
      int cell = ((world - 950) / 290).floor();
      cell <= (world / 290).ceil();
      cell++
    ) {
      final x = cell.isEven ? 79.0 : 330.0;
      final y = world - cell * 290 - sceneryNoise(cell, 820) * 65;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 17,
          height: 35 + sceneryNoise(cell, 821) * 30,
        ),
        Paint()
          ..shader = Gradient.radial(Offset(x, y), 30, [
            (model.daylight == Daylight.night
                    ? const Color(0xFFC3AD7D)
                    : const Color(0xFF9BB6BF))
                .withValues(alpha: rain * .16),
            const Color(0x009BB6BF),
          ]),
      );
    }
    if (model.phase == GamePhase.playing && rain > .2) {
      for (int side = -1; side <= 1; side += 2) {
        for (int i = 0; i < 8; i++) {
          final t = (time * 2.8 + i / 8) % 1;
          final x =
              model.playerX + side * (model.vehicle.halfWidth + 3 + t * 12);
          final y = GameConfig.playerY + 30 + t * 55;
          c.drawOval(
            Rect.fromCenter(
              center: Offset(x, y),
              width: 2 + t * 5,
              height: 3 + t * 9,
            ),
            Paint()
              ..color = const Color(
                0xFFCBDCDD,
              ).withValues(alpha: (1 - t) * rain * .24),
          );
        }
      }
    }
  }
}
