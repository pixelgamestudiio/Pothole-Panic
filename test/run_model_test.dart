import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothole_panic/game/game_config.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/managers/collision_manager.dart';
import 'package:pothole_panic/game/managers/spawn_manager.dart';
import 'package:pothole_panic/game/run_model.dart';

void main() {
  RunModel run() => RunModel(random: Random(42))..start();
  test('Scoring keeps fractional distance at 30, 60 and 120 Hz', () {
    final scores = <int>[];
    for (final fps in [30, 60, 120]) {
      final model = run()..nextRowDistance = 100000;
      for (int i = 0; i < fps * 10; i++) {
        model.step(1 / fps);
      }
      scores.add(model.score);
    }
    expect(scores.toSet().length, 1);
  });
  test(
    'Every row preserves an adjacent reachable safe lane over 10,000 rows',
    () {
      final spawner = SpawnManager(random: Random(8));
      int previous = 1;
      for (int i = 0; i < 10000; i++) {
        final row = spawner.nextRow(i / 10);
        final holes = row
            .where((e) => e.kind == ItemKind.pothole)
            .map((e) => e.lane)
            .toSet();
        expect(holes.contains(spawner.safeLane), false);
        expect((spawner.safeLane - previous).abs(), lessThanOrEqualTo(1));
        expect(
          spawner.rowSpacingAt(i / 10) / (520 * 2),
          greaterThanOrEqualTo(.68),
        );
        for (final person in row.where((e) => e.kind == ItemKind.passenger)) {
          expect(holes.contains(person.lane), false);
        }
        previous = spawner.safeLane;
      }
    },
  );
  test('Boost expires without changing the base difficulty speed', () {
    final model = run()..nextRowDistance = 100000;
    expect(model.horn(), true);
    expect(model.horn(), false);
    expect(model.speed, 520);
    for (int i = 0; i < 121; i++) {
      model.step(GameConfig.fixedStep);
    }
    expect(model.boostLeft, 0);
    expect(model.speed, closeTo(model.spawner.speedAt(model.elapsed), .0001));
    expect(model.cooldown, greaterThan(0));
  });
  test('Paused run freezes score, cooldown, objects and input', () {
    final model = run()..horn();
    model.pause();
    final time = model.elapsed,
        distance = model.distance,
        cooldown = model.cooldown;
    model.step(4);
    model.switchLane(-1);
    expect(model.elapsed, time);
    expect(model.distance, distance);
    expect(model.cooldown, cooldown);
    expect(model.lane, 1);
  });
  test(
    'Swept collision catches a pothole crossing the player in one frame',
    () {
      final item = RoadItem(kind: ItemKind.pothole, lane: 1, y: 720);
      expect(CollisionManager.intersects(item, 470, 210, 210), true);
      expect(CollisionManager.intersects(item, 470, 114, 114), false);
    },
  );
  test('Pickup is awarded exactly once and boost doubles fare', () {
    final model = run()..horn();
    model.items.add(RoadItem(kind: ItemKind.passenger, lane: 1, y: 595));
    model.step(.01);
    model.step(.01);
    expect(model.fare, 20);
    expect(model.passengers, 1);
  });
  test(
    'Only one death event, one revive, cleared hazards and safe restart',
    () {
      final model = run();
      model.items.addAll(
        List.generate(
          2,
          (_) => RoadItem(kind: ItemKind.pothole, lane: 1, y: 590),
        ),
      );
      model.step(.01);
      model.step(.7);
      expect(model.phase, GamePhase.gameOver);
      expect(model.events.where((e) => e == GameEvent.crash).length, 1);
      expect(model.revive(), true);
      expect(model.shielded, true);
      expect(model.items, isEmpty);
      model.phase = GamePhase.gameOver;
      expect(model.revive(), false);
      model.start();
      expect(model.continued, false);
      expect(model.score, 0);
      expect(model.cooldown, 0);
      expect(model.items, isEmpty);
    },
  );
  test('Lane changes are bounded and rapid reversals remain continuous', () {
    final model = run();
    model.switchLane(-1);
    model.step(.08);
    final before = model.playerX;
    model.switchLane(1);
    expect(model.playerX, before);
    model.step(.2);
    expect(model.playerX, 210);
    for (int i = 0; i < 10; i++) {
      model.switchLane(1);
    }
    expect(model.lane, 2);
  });
  test('Long runs remove offscreen objects and cap speed', () {
    final model = run()..protection = 2000;
    for (int i = 0; i < 120 * 180; i++) {
      model.step(GameConfig.fixedStep);
    }
    expect(model.speed, 520);
    expect(model.items.length, lessThan(12));
  });
}
