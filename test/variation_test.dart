import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothole_panic/game/game_config.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/managers/spawn_manager.dart';
import 'package:pothole_panic/game/run_model.dart';
import 'package:pothole_panic/game/vehicle.dart';

void main() {
  test(
    'Thousands of sequences preserve timed corridors including stagger tails',
    () {
      for (final meters in [0.0, 700.0, 1500.0, 3500.0, 6500.0, 12000.0]) {
        final s = SpawnManager(random: Random(44));
        int before = 1;
        for (int j = 0; j < 2000; j++) {
          final items = s.nextRow(meters);
          final speed = s.planningSpeed(meters);
          expect((s.beats.first.safeLane - before).abs(), lessThanOrEqualTo(1));
          for (int i = 0; i < s.beats.length; i++) {
            final beat = s.beats[i];
            expect(beat.blocked, isNot(contains(beat.safeLane)));
            if (i > 0) {
              final previous = s.beats[i - 1];
              expect(
                (beat.offset - previous.end) / speed + .000001,
                greaterThanOrEqualTo(
                  SpawnManager.clearanceSeconds(
                    beat.safeLane - previous.safeLane,
                  ),
                ),
              );
            }
          }
          expect(
            (s.rowSpacingAt(meters) - s.beats.last.end) / speed + .000001,
            greaterThanOrEqualTo(.72),
          );
          for (final reward in items.where((e) => !e.kind.isHazard)) {
            expect(
              items.where(
                (e) =>
                    e.kind.isHazard &&
                    e.lane == reward.lane &&
                    (e.y - reward.y).abs() < 80,
              ),
              isEmpty,
            );
          }
          before = s.safeLane;
        }
      }
    },
  );

  test(
    'Hard road varies cadence, obstacle count, holds, crossings and rewards',
    () {
      final s = SpawnManager(random: Random(9));
      final patterns = <RoadPattern>{}, gaps = <int>{}, counts = <int>{};
      int holds = 0, crosses = 0, unrewarded = 0, optional = 0;
      for (int j = 0; j < 1000; j++) {
        final items = s.nextRow(12000);
        patterns.add(s.pattern);
        counts.addAll(s.beats.map((b) => b.blocked.length));
        for (int i = 1; i < s.beats.length; i++) {
          final delta = (s.beats[i].safeLane - s.beats[i - 1].safeLane).abs();
          if (delta == 0) holds++;
          if (delta == 2) crosses++;
          gaps.add(((s.beats[i].offset - s.beats[i - 1].end) / 10).round());
        }
        for (final beat in s.beats) {
          final rewards = items.where(
            (e) => !e.kind.isHazard && (e.y + 70 + beat.offset).abs() < 1,
          );
          if (rewards.isEmpty) unrewarded++;
          optional += rewards.where((r) => r.lane != beat.safeLane).length;
        }
      }
      expect(patterns, containsAll(RoadPattern.values));
      expect(counts, containsAll([1, 2]));
      expect(gaps.length, greaterThan(40));
      expect(holds, greaterThan(200));
      expect(crosses, greaterThan(30));
      expect(unrewarded, greaterThan(500));
      expect(optional, greaterThan(0));
    },
  );

  test('Later distances unlock wider crossings and longer combinations', () {
    for (final meters in [1500.0, 3500.0, 6500.0]) {
      final s = SpawnManager(random: Random(27));
      final patterns = <RoadPattern>{};
      int longest = 0;
      for (int i = 0; i < 200; i++) {
        s.nextRow(meters);
        patterns.add(s.pattern);
        longest = max(longest, s.beats.length);
      }
      expect(patterns.contains(RoadPattern.crossing), meters >= 3000);
      expect(longest, meters >= 6000 ? 4 : 3);
    }
  });

  test(
    'Every vehicle traverses complete sequences with collisions and oil recovery',
    () {
      for (final vehicle in Vehicle.values) {
        for (final seed in [3, 17, 42]) {
          final m = RunModel()..start(selectedVehicle: vehicle, seed: seed);
          m.distance = 120000;
          m.elapsed = 35;
          var seen = m.spawner.beats;
          final path = <({double arrive, double tail, int lane})>[];
          double previousTail = -1000;
          for (int frame = 0; frame < 120 * 90; frame++) {
            while (path.isNotEmpty && m.distance > path.first.tail + 50) {
              previousTail = path.removeAt(0).tail;
            }
            if (path.isNotEmpty &&
                m.distance > previousTail + 50 &&
                m.distance > path.first.arrive - 650 &&
                m.laneProgress >= .65) {
              m.switchLane((path.first.lane - m.lane).sign);
            }
            if (frame % 840 == 0) m.skidLeft = 1;
            m.step(GameConfig.fixedStep);
            if (!identical(seen, m.spawner.beats)) {
              seen = m.spawner.beats;
              final first = m.items.where((e) => e.kind.isHazard).last;
              // Last generated hazard belongs to the last beat (possibly staggered).
              final last = seen.last;
              final offset = last.blocked.length == 2 ? last.end : last.offset;
              final origin = m.distance - (first.y + 70 + offset);
              path.addAll(
                seen.map(
                  (b) => (
                    arrive: origin + 666 + b.offset,
                    tail: origin + 666 + b.end,
                    lane: b.safeLane,
                  ),
                ),
              );
            }
            expect(
              m.health,
              3,
              reason: '${vehicle.name}, seed $seed, frame $frame',
            );
          }
          expect(m.phase, GamePhase.playing);
        }
      }
    },
  );
}
