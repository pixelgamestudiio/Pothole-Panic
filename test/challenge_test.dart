import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothole_panic/game/game_config.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/road_environment.dart';
import 'package:pothole_panic/game/run_model.dart';
import 'package:pothole_panic/game/vehicle.dart';

void advance(RunModel model, double seconds) {
  for (int i = 0; i < (seconds * 120).round(); i++) {
    model.step(GameConfig.fixedStep);
  }
}

void main() {
  test('Oil visibly disrupts balance for one second then recovers unaided', () {
    for (final vehicle in Vehicle.values) {
      final model = RunModel()..start(selectedVehicle: vehicle);
      model.nextRowDistance = 100000;
      final normalSteering = model.steeringSeconds;
      model.items.add(
        RoadItem(kind: ItemKind.oil, lane: 1, y: GameConfig.playerY),
      );
      model.step(GameConfig.fixedStep);
      expect(model.skidLeft, 1);
      expect(model.steeringSeconds, greaterThan(normalSteering));
      double maxDisplacement = 0;
      for (int i = 0; i < 120; i++) {
        model.step(GameConfig.fixedStep);
        maxDisplacement = max(
          maxDisplacement,
          (model.playerX - GameConfig.laneX(1)).abs(),
        );
      }
      expect(maxDisplacement, greaterThan(6));
      expect(maxDisplacement, lessThan(32));
      expect(model.skidLeft, closeTo(0, 1e-8));
      advance(model, .5);
      expect(model.playerX, closeTo(GameConfig.laneX(1), .1));
      expect(model.health, 3);
      expect(model.phase, GamePhase.playing);
    }
  });

  test(
    'Horn shield expires at one second; recharge takes 16 active seconds',
    () {
      final model = RunModel()..start();
      model.nextRowDistance = 100000;
      expect(model.horn(), isTrue);
      advance(model, 1.1);
      expect(model.shielded, isFalse);
      advance(model, 4);
      expect(
        model.horn(),
        isFalse,
      ); // Old five-second recharge must not return.
      final remaining = model.cooldown;
      model.pause();
      model.step(100);
      expect(model.cooldown, remaining);
      model.phase = GamePhase.gameOver;
      model.revive();
      expect(model.cooldown, remaining); // Rescue does not refill the horn.
      advance(model, 10.8);
      expect(model.horn(), isFalse);
      advance(model, .2);
      expect(model.horn(), isTrue);
    },
  );

  test(
    'Automatic light transitions are continuous at every cycle boundary',
    () {
      final model = RunModel()..start();
      for (final boundary in [500.0, 1000.0, 2000.0, 2500.0, 3000.0]) {
        model.distance = (boundary - .001) * 10;
        final before = Daylight.values.map(model.lightWeight).toList();
        model.distance = (boundary + .001) * 10;
        final after = Daylight.values.map(model.lightWeight).toList();
        for (int i = 0; i < 3; i++) {
          expect(after[i], closeTo(before[i], .0001));
        }
        expect(after.reduce((a, b) => a + b), closeTo(1, 1e-8));
      }
    },
  );
}
