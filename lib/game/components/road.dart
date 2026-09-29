import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../road_environment.dart';
import '../run_model.dart';
import 'palette.dart';

/// World-space scenery: irregular setbacks, roofs, open verges and landmarks.
/// Props keep their appearance as they pass; nothing is randomized per frame.
class Road extends Component {
  Road(this.model);
  final RunModel model;
  bool get night => model.lightWeight(Daylight.night) > .1;
  double get shadow => 8 + 12 * model.lightWeight(Daylight.afternoon);
  static const grounds = [
    Color(0xFFB3AB8F),
    Color(0xFFB0A08A),
    Color(0xFF748C62),
    Color(0xFFB7A07C),
  ];

  @override
  void render(Canvas canvas) {
    final c = canvas;
    final world = model.scroll + GameConfig.playerY;
    final first = ((world - 1100) / 360).floor();
    final last = ((world + 400) / 360).ceil();
    for (int cell = first; cell <= last; cell++) {
      final y = world - cell * 360;
      c.drawRect(
        Rect.fromLTWH(0, y - 360, 420, 361),
        Paint()..color = grounds[District.at(cell * 36.0).index],
      );
    }
    // Solid verges replace the high-contrast repeating black/white curb.
    c.drawRect(
      const Rect.fromLTWH(57, 0, 306, 800),
      Paint()..color = const Color(0xFF77796C),
    );
    c.drawRect(
      const Rect.fromLTWH(62, 0, 296, 800),
      Paint()..color = const Color(0xFF242F30),
    );
    c.drawRect(
      const Rect.fromLTWH(68, 0, 284, 800),
      Paint()
        ..shader = Gradient.linear(
          const Offset(68, 0),
          const Offset(352, 0),
          [
            const Color(0xFF3E4847),
            const Color(0xFF56605B),
            const Color(0xFF3D4847),
          ],
          [0, .5, 1],
        ),
    );
    if (model.rain > 0) {
      c.drawRect(
        const Rect.fromLTWH(68, 0, 284, 800),
        Paint()
          ..color = const Color(0xFF162D3A).withValues(alpha: model.rain * .30),
      );
      for (final x in [95.0, 190.0, 287.0]) {
        c.drawRect(
          Rect.fromLTWH(x, 0, 18, 800),
          Paint()
            ..shader = Gradient.linear(
              Offset(x, 0),
              Offset(x + 18, 0),
              [
                const Color(0x00A4BECB),
                const Color(0xFFA4BECB).withValues(alpha: model.rain * .08),
                const Color(0x00A4BECB),
              ],
              [0, .5, 1],
            ),
        );
      }
    }
    for (int cell = first; cell <= last; cell++) {
      for (int i = 0; i < 35; i++) {
        final x = 72 + sceneryNoise(cell, i + 1) * 276;
        final y = world - cell * 360 - sceneryNoise(cell, i + 65) * 360;
        c.drawCircle(
          Offset(x, y),
          .5 + sceneryNoise(cell, i + 110),
          Paint()..color = const Color(0x185D6D6B),
        );
      }
      final y = world - cell * 360;
      if (cell % 3 == 0) {
        c.drawLine(
          Offset(73, y - 61),
          Offset(347, y - 54),
          Paint()
            ..color = const Color(0x28212E2D)
            ..strokeWidth = 2,
        );
      }
      for (final x in [61.0, 352.0]) {
        fillRound(
          c,
          Rect.fromLTWH(x, y - 120, 7, 20),
          const Color(0xFF293D3A),
          1,
        );
        for (int k = 0; k < 4; k++) {
          c.drawLine(
            Offset(x, y - 118 + k * 5),
            Offset(x + 7, y - 118 + k * 5),
            Paint()..color = const Color(0xFF778279),
          );
        }
      }
    }
    for (int i = -1; i < 9; i++) {
      final y = i * 120 + model.scroll % 120;
      for (final x in [161.0, 257.0]) {
        fillRound(c, Rect.fromLTWH(x, y, 2, 38), const Color(0x8AD7DBBE), 1);
      }
    }
    for (final x in [70.0, 348.0]) {
      c.drawLine(
        Offset(x, 0),
        Offset(x, 800),
        Paint()
          ..color = const Color(0x779DAB91)
          ..strokeWidth = 1.2,
      );
    }
    for (int cell = first; cell <= last; cell++) {
      for (int side = 0; side < 2; side++) {
        final salt = side * 83;
        final y = world - cell * 360 - 30 - sceneryNoise(cell, salt + 3) * 130;
        final district = District.at(cell * 36.0);
        c.save();
        if (side == 1) {
          c.translate(420, 0);
          c.scale(-1, 1);
        }
        switch (district) {
          case District.residential:
            if (sceneryNoise(cell, salt + 8) > .25) {
              _house(
                c,
                -8 - sceneryNoise(cell, salt + 9) * 8,
                y,
                43 + sceneryNoise(cell, salt + 10) * 15,
                70 + sceneryNoise(cell, salt + 11) * 52,
                cell + salt,
                false,
              );
            } else {
              fillRound(
                c,
                Rect.fromLTWH(0, y, 48, 90),
                const Color(0xFF829269),
                3,
              );
              c.drawRect(
                Rect.fromLTWH(-2, y, 50, 90),
                Paint()
                  ..color = const Color(0xFFCCC2A2)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4,
              );
              _tree(c, 16, y + 40, 15, cell);
            }
            _tree(
              c,
              22 + sceneryNoise(cell, salt + 12) * 15,
              y + 160,
              13 + sceneryNoise(cell, salt + 13) * 9,
              cell + salt,
            );
            if (cell % 3 == side) _scooter(c, 48, y + 105);
          case District.market:
            _house(
              c,
              -10,
              y,
              57,
              85 + sceneryNoise(cell, salt + 14) * 45,
              cell + salt,
              true,
            );
            _stall(c, 28, y + 180, cell + side);
            if (sceneryNoise(cell, salt + 15) > .6) {
              _tree(c, 10, y + 280, 16, cell);
            }
          case District.fields:
            for (int row = 0; row < 5; row++) {
              c.drawLine(
                Offset(0, y + row * 30),
                Offset(46, y + row * 30 + 15),
                Paint()
                  ..color = const Color(0x55718C54)
                  ..strokeWidth = 6,
              );
            }
            if (sceneryNoise(cell, salt + 16) > .4) {
              _tree(c, 20, y + 170, 22, cell + salt);
            }
            if (cell % 4 == side) {
              fillRound(
                c,
                Rect.fromLTWH(43, y + 240, 12, 25),
                const Color(0xFFE3DCBD),
                4,
              );
              fillRound(
                c,
                Rect.fromLTWH(43, y + 240, 12, 8),
                Palette.yellow,
                3,
              );
              c.drawLine(
                Offset(46, y + 255),
                Offset(52, y + 255),
                Paint()
                  ..color = Palette.ink
                  ..strokeWidth = 2,
              );
            }
          case District.works:
            _works(c, y, cell + side);
            if (sceneryNoise(cell, salt + 17) > .65) {
              _tree(c, 10, y + 275, 17, cell);
            }
        }
        if (district != District.fields && cell % 2 == side) _lamp(c, y + 255);
        c.restore();
      }
    }
  }

  void _house(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    int seed,
    bool shop,
  ) {
    const roofs = [
      Color(0xFFAD7057),
      Color(0xFF819896),
      Color(0xFFB49D79),
      Color(0xFF728C7A),
    ];
    fillRound(
      c,
      Rect.fromLTWH(x + shadow, y + shadow, w + 2, h + 2),
      const Color(0x300E2420),
      3,
    );
    fillRound(c, Rect.fromLTWH(x + 5, y + 7, w, h), const Color(0xFF596963), 2);
    fillRound(
      c,
      Rect.fromLTWH(x, y, w, h),
      roofs[seed.abs() % roofs.length],
      2,
    );
    c.drawRect(
      Rect.fromLTWH(x + 3, y + 3, w - 6, h - 6),
      Paint()
        ..color = const Color(0x55E6DDC0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    fillRound(
      c,
      Rect.fromLTWH(x + 8, y + 13, 18, 27),
      const Color(0xFF3A565E),
      2,
    );
    for (int i = 1; i < 3; i++) {
      c.drawLine(
        Offset(x + 8, y + 13 + i * 8),
        Offset(x + 26, y + 13 + i * 8),
        Paint()..color = const Color(0xFF729596),
      );
    }
    c.drawOval(
      Rect.fromLTWH(x + w - 18, y + h - 25, 12, 17),
      Paint()..color = const Color(0xFF334844),
    );
    c.drawOval(
      Rect.fromLTWH(x + w - 18, y + h - 28, 12, 10),
      Paint()..color = const Color(0xFF687977),
    );
    for (int i = 0; i < 3; i++) {
      fillRound(
        c,
        Rect.fromLTWH(x + w + 2, y + 17 + i * 21, 3, 9),
        night ? const Color(0xFFFFD888) : const Color(0xFF354A45),
        0,
      );
    }
    if (shop) {
      fillRound(
        c,
        Rect.fromLTWH(x + w - 7, y + 5, 17, h - 10),
        const Color(0xFF415B55),
        1,
      );
      for (int i = 0; i < (h - 12) / 12; i++) {
        fillRound(
          c,
          Rect.fromLTWH(x + w - 7, y + 6 + i * 12, 16, 10),
          i.isEven ? const Color(0xFFE1B87F) : const Color(0xFF936451),
          0,
        );
      }
      fillRound(c, Rect.fromLTWH(x + 3, y + h - 16, w - 8, 12), Palette.ink, 2);
      // Keep roof lettering readable on both sides of the mirrored street.
      c.save();
      c.translate(x + w / 2, y + h - 15);
      if (c.getTransform()[0] < 0) c.scale(-1, 1);
      drawLabel(c, seed.isEven ? 'CHAI' : 'MART', Offset.zero, size: 7);
      c.restore();
    }
  }

  void _tree(Canvas c, double x, double y, double radius, int seed) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x + shadow, y + shadow * 1.4),
        width: radius * 2.1,
        height: radius * 2.6,
      ),
      Paint()..color = const Color(0x300D2821),
    );
    c.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = const Color(0xFF3C5E43),
    );
    for (int k = 0; k < 7; k++) {
      final angle = k * 2.4 + seed;
      c.drawCircle(
        Offset(x + cos(angle) * radius * .4, y + sin(angle) * radius * .4),
        radius * (.38 + sceneryNoise(seed, k) * .25),
        Paint()
          ..color = k.isEven
              ? const Color(0xFF69885A)
              : const Color(0xFF51774C),
      );
    }
    c.drawCircle(
      Offset(x - radius * .25, y - radius * .25),
      radius * .37,
      Paint()..color = const Color(0xFF7A955F),
    );
  }

  void _scooter(Canvas c, double x, double y) {
    fillRound(
      c,
      Rect.fromLTWH(x - 4, y - 14, 8, 30),
      const Color(0xFF233B36),
      3,
    );
    fillRound(
      c,
      Rect.fromLTWH(x - 5, y - 9, 10, 22),
      const Color(0xFFB9C2AA),
      4,
    );
    fillRound(c, Rect.fromLTWH(x - 3, y + 2, 6, 9), Palette.ink, 2);
  }

  void _stall(Canvas c, double x, double y, int seed) {
    fillRound(
      c,
      Rect.fromLTWH(x + 4, y + 6, 23, 34),
      const Color(0x33122520),
      2,
    );
    fillRound(c, Rect.fromLTWH(x, y, 22, 32), const Color(0xFFB48253), 2);
    for (int k = 0; k < 6; k++) {
      c.drawCircle(
        Offset(x + 5 + (k % 2) * 10, y + 6 + (k ~/ 2) * 10),
        3.5,
        Paint()
          ..color = seed.isEven
              ? const Color(0xFFC39C48)
              : const Color(0xFF82964B),
      );
    }
    fillRound(
      c,
      Rect.fromLTWH(x - 3, y - 10, 28, 13),
      const Color(0xFF638E8C),
      2,
    );
  }

  void _works(Canvas c, double y, int seed) {
    for (int i = 0; i < 4; i++) {
      fillRound(
        c,
        Rect.fromLTWH(3 + (i % 2) * 22.0, y + (i ~/ 2) * 44, 18, 35),
        const Color(0xFF9B7456),
        2,
      );
      c.drawLine(
        Offset(4 + (i % 2) * 22, y + (i ~/ 2) * 44 + 16),
        Offset(19 + (i % 2) * 22, y + (i ~/ 2) * 44 + 16),
        Paint()..color = const Color(0xFFBF9B75),
      );
    }
    fillRound(c, Rect.fromLTWH(48, y - 10, 4, 157), const Color(0xFF657576), 0);
    for (int i = 0; i < 6; i++) {
      fillRound(
        c,
        Rect.fromLTWH(45, y - 10 + i * 26, 9, 3),
        const Color(0xFFCBD0B8),
        1,
      );
    }
    c.drawOval(
      Rect.fromLTWH(-12, y + 140, 58, 47),
      Paint()..color = const Color(0xFFC8B58D),
    );
    if (seed.isEven) {
      fillRound(
        c,
        Rect.fromLTWH(13, y + 220, 31, 45),
        const Color(0xFFC49A4E),
        4,
      );
      fillRound(
        c,
        Rect.fromLTWH(17, y + 225, 23, 17),
        const Color(0xFF3A504C),
        3,
      );
      fillRound(
        c,
        Rect.fromLTWH(24, y + 259, 8, 42),
        const Color(0xFFE1B85D),
        2,
      );
    }
  }

  void _lamp(Canvas c, double y) {
    c.drawLine(
      Offset(49, y + 20),
      Offset(59, y),
      Paint()
        ..color = const Color(0xFF334944)
        ..strokeWidth = 2,
    );
    fillRound(
      c,
      Rect.fromLTWH(54, y - 3, 9, 5),
      night ? const Color(0xFFF4D393) : const Color(0xFFCFD6C1),
      2,
    );
    if (night) {
      c.drawCircle(
        Offset(66, y + 4),
        40,
        Paint()
          ..shader = Gradient.radial(Offset(66, y + 4), 40, [
            const Color(0x38FFE2A3),
            const Color(0x00FFE2A3),
          ]),
      );
    }
  }
}
