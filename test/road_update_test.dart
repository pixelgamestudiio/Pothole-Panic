import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/game/game_config.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/managers/collision_manager.dart';
import 'package:pothole_panic/game/managers/spawn_manager.dart';
import 'package:pothole_panic/game/run_model.dart';
import 'package:pothole_panic/game/vehicle.dart';
import 'package:pothole_panic/services/save_service.dart';

void main() {
  RunModel run([Vehicle vehicle = Vehicle.auto]) => RunModel(random: Random(5))
    ..start(selectedVehicle: vehicle)
    ..nextRowDistance = 100000;
  void hit(RunModel model, ItemKind kind) {
    model.items.add(
      RoadItem(kind: kind, lane: model.lane, y: GameConfig.playerY),
    );
    model.step(GameConfig.fixedStep);
  }

  void advance(RunModel model, double seconds) {
    for (var i = 0; i < (seconds / GameConfig.fixedStep).ceil(); i++) {
      model.step(GameConfig.fixedStep);
    }
  }

  test(
    'Three separate impacts end a run; grace period prevents double damage',
    () {
      final model = run();
      hit(model, ItemKind.pothole);
      expect(model.health, 2);
      hit(model, ItemKind.barricade);
      expect(model.health, 2);
      advance(model, 1.4);
      hit(model, ItemKind.barricade);
      expect(model.health, 1);
      advance(model, 1.4);
      hit(model, ItemKind.barricade);
      advance(model, .7);
      expect(model.phase, GamePhase.gameOver);
      expect(model.lastCrash, ItemKind.barricade);
      expect(model.events.where((e) => e == GameEvent.crash), hasLength(1));
      expect(model.revive(), isTrue);
      expect(model.health, 3);
      expect(model.shielded, isTrue);
    },
  );

  test(
    'Oil is recoverable, bounded and responds to steering in every vehicle',
    () {
      for (final vehicle in Vehicle.values) {
        final model = run(vehicle)..elapsed = 35;
        hit(model, ItemKind.oil);
        expect(model.skidLeft, greaterThan(0));
        model.switchLane(-1);
        advance(model, .5);
        expect((model.playerX - GameConfig.laneX(0)).abs(), lessThan(32));
        model.switchLane(1);
        advance(model, .5);
        expect((model.playerX - GameConfig.laneX(1)).abs(), lessThan(32));
        advance(model, 4);
        expect(model.skidLeft, 0);
        expect(model.health, 3);
        expect(model.phase, GamePhase.playing);
        expect(model.playerX, closeTo(GameConfig.laneX(1), .01));
      }
    },
  );

  test('Horn clears oil effects and shields hazards', () {
    final model = run();
    hit(model, ItemKind.oil);
    model.horn();
    expect(model.skidLeft, 0);
    hit(model, ItemKind.barricade);
    expect(model.health, 3);
  });

  test(
    'Weather eases between dry and rain; pause freezes effects and coins',
    () {
      final model = run();
      expect(model.rain, 0);
      model.elapsed = 27.5;
      expect(model.rain, .5);
      model.elapsed = 35;
      expect(model.rain, 1);
      hit(model, ItemKind.oil);
      final time = model.elapsed, skid = model.skidLeft;
      model.pause();
      model.step(10);
      expect(model.elapsed, time);
      expect(model.skidLeft, skid);
      model.elapsed = 70;
      expect(model.rain, 0);
    },
  );

  test(
    'Coin awards once, survives rescue, and resets only for the next run',
    () {
      final model = run();
      hit(model, ItemKind.coin);
      advance(model, .1);
      expect(model.coins, 5);
      model.phase = GamePhase.gameOver;
      model.revive();
      expect(model.coins, 5);
      model.start();
      expect(model.coins, 0);
    },
  );

  test(
    'Car grip is stronger; bike steering and collision footprint are smaller',
    () {
      final car = run(Vehicle.car), bike = run(Vehicle.bike);
      hit(car, ItemKind.oil);
      hit(bike, ItemKind.oil);
      expect(car.skidLeft, 1);
      expect(bike.skidLeft, 1);
      advance(car, .35);
      advance(bike, .35);
      expect(car.skidOffset.abs(), lessThan(bike.skidOffset.abs()));
      expect(car.steeringSeconds, greaterThan(bike.steeringSeconds));
      final item = RoadItem(kind: ItemKind.barricade, lane: 1, y: 596);
      expect(
        CollisionManager.intersects(
          item,
          595,
          170,
          170,
          playerHalfWidth: Vehicle.car.halfWidth,
        ),
        isTrue,
      );
      expect(
        CollisionManager.intersects(
          item,
          595,
          170,
          170,
          playerHalfWidth: Vehicle.bike.halfWidth,
        ),
        isFalse,
      );
    },
  );

  test('All hazards appear and a pickup never overlaps a hazard lane', () {
    final spawner = SpawnManager(random: Random(9));
    final kinds = <ItemKind>{};
    for (var i = 0; i < 1000; i++) {
      final row = spawner.nextRow(2000);
      kinds.addAll(row.map((e) => e.kind));
      for (final pickup in row.where((e) => !e.kind.isHazard)) {
        expect(
          row.where(
            (e) =>
                e.kind.isHazard &&
                e.lane == pickup.lane &&
                (e.y - pickup.y).abs() < 80,
          ),
          isEmpty,
        );
      }
    }
    expect(kinds, containsAll(ItemKind.values));
  });

  test(
    'Worst handling can reach the next safe corridor at boosted top speed',
    () {
      for (final vehicle in Vehicle.values) {
        final model = run(vehicle)
          ..elapsed = 35
          ..skidLeft = 1;
        model.switchLane(1);
        // At the 0.72s boosted gap, allow 0.22s before completing a lane change.
        advance(model, .5);
        final hazard = RoadItem(
          kind: ItemKind.barricade,
          lane: 1,
          y: 596,
          radius: 31,
        );
        expect(
          CollisionManager.intersects(
            hazard,
            595,
            model.playerX,
            model.playerX,
            playerHalfWidth: vehicle.halfWidth,
          ),
          isFalse,
        );
        expect(model.steeringSeconds, lessThanOrEqualTo(.38));
      }
    },
  );

  test(
    'Old saves migrate without changing high score; purchases persist once',
    () async {
      SharedPreferences.setMockInitialValues({'best': 234, 'sound': false});
      final prefs = await SharedPreferences.getInstance();
      final save = SaveService(prefs);
      expect(save.best, 234);
      expect(save.coins, 0);
      expect(save.selectedVehicle, Vehicle.auto);
      expect(await save.selectOrUnlock(Vehicle.car), isFalse);
      await save.creditCoins(150);
      final results = await Future.wait([
        save.selectOrUnlock(Vehicle.car),
        save.selectOrUnlock(Vehicle.car),
        save.creditCoins(5),
      ]);
      expect(results.every((e) => e), isTrue);
      final reloaded = SaveService(prefs);
      expect(reloaded.coins, 55);
      expect(reloaded.selectedVehicle, Vehicle.car);
      expect(reloaded.isUnlocked(Vehicle.car), isTrue);
      expect(reloaded.best, 234);
      expect(reloaded.sound, isFalse);
      expect(await reloaded.creditCoins(-1), isFalse);
      expect(reloaded.coins, 55);
    },
  );

  test(
    'Corrupt garage data falls back to starter without deleting old scores',
    () async {
      SharedPreferences.setMockInitialValues({
        'best': 555,
        'garage_v1': 'invalid',
      });
      final save = SaveService(await SharedPreferences.getInstance());
      expect(save.best, 555);
      expect(save.coins, 0);
      expect(save.selectedVehicle, Vehicle.auto);
      expect(save.isUnlocked(Vehicle.car), isFalse);
    },
  );
}
