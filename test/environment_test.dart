import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/managers/spawn_manager.dart';
import 'package:pothole_panic/game/road_environment.dart';
import 'package:pothole_panic/game/run_model.dart';
import 'package:pothole_panic/services/save_service.dart';

void main() {
  test('Levels use actual meters, not fare, coins or elapsed time', () {
    final model = RunModel()
      ..start()
      ..fare = 100000
      ..coins = 100000
      ..elapsed = 100;
    expect(model.difficulty, Difficulty.easy);
    for (final (distance, expected) in [
      (4999.9, Difficulty.easy),
      (5000.0, Difficulty.medium),
      (9999.9, Difficulty.medium),
      (10000.0, Difficulty.hard),
    ]) {
      model.distance = distance;
      expect(model.difficulty, expected);
    }
  });
  test('Speed is continuous at milestones, increasing and capped', () {
    final spawner = SpawnManager();
    double previous = 0;
    for (double m = 0; m <= 10000; m += 10) {
      expect(spawner.speedAt(m), greaterThanOrEqualTo(previous));
      expect(spawner.speedAt(m), lessThanOrEqualTo(740));
      previous = spawner.speedAt(m);
    }
    for (final m in [500.0, 1000.0, 3000.0]) {
      expect(
        (spawner.speedAt(m + .001) - spawner.speedAt(m - .001)).abs(),
        lessThan(.001),
      );
    }
    expect(spawner.speedAt(0), 340);
    expect(spawner.speedAt(500), 440);
    expect(spawner.speedAt(1000), 540);
    expect(spawner.speedAt(99999), 740);
  });
  test(
    'Milestone banner triggers once; pause freezes and rescue preserves progress',
    () {
      final model = RunModel()
        ..start()
        ..distance = 4999
        ..nextRowDistance = 10000;
      model.step(.01);
      expect(model.difficulty, Difficulty.medium);
      expect(model.stageBannerLeft, 3);
      model.pause();
      model.step(4);
      expect(model.stageBannerLeft, 3);
      model.resume();
      model.step(.01);
      expect(model.stageBannerLeft, lessThan(3));
      model.phase = GamePhase.gameOver;
      model.revive();
      expect(model.difficulty, Difficulty.medium);
      model.start();
      expect(model.difficulty, Difficulty.easy);
      expect(model.stageBannerLeft, 0);
    },
  );
  test(
    'Scenery is deterministic and district sequence includes open stretches',
    () {
      expect([0, 800, 1600, 2400, 3200].map((m) => District.at(m.toDouble())), [
        District.residential,
        District.market,
        District.fields,
        District.works,
        District.residential,
      ]);
      final samples = List.generate(100, (i) => sceneryNoise(i, 83));
      expect(samples.toSet().length, greaterThan(95));
      for (int i = 0; i < 100; i++) {
        expect(samples[i], sceneryNoise(i, 83));
        expect(samples[i], inInclusiveRange(0, 1));
      }
    },
  );
  test(
    'Lighting follows distance, blends, pauses, survives rescue and resets',
    () async {
      SharedPreferences.setMockInitialValues({
        'best': 120,
        'daylight': 'night',
      });
      final prefs = await SharedPreferences.getInstance();
      final save = SaveService(prefs);
      expect(save.best, 120);
      final model = RunModel()..start();
      expect(
        model.daylight,
        Daylight.day,
      ); // Old preference cannot override it.
      for (final (meters, light) in [
        (500.0, Daylight.afternoon),
        (1000.0, Daylight.night),
        (1999.0, Daylight.night),
        (2000.0, Daylight.day),
      ]) {
        model.distance = meters * 10;
        expect(model.daylight, light);
      }
      model.distance = 9500;
      expect(model.lightWeight(Daylight.night), .5);
      model.pause();
      model.step(10);
      expect(model.lightWeight(Daylight.night), .5);
      model.distance = 12000;
      model.phase = GamePhase.gameOver;
      model.revive();
      expect(model.daylight, Daylight.night);
      model.start();
      expect(model.daylight, Daylight.day);
    },
  );
}
