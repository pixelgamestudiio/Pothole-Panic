import 'dart:math';
import '../game_config.dart';
import '../game_state.dart';

enum RoadPattern { single, gates, hold, stagger, slalom, crossing }

/// A checkpoint in a generated sequence. The route is for validation, not HUD.
class RoadBeat {
  RoadBeat(this.offset, this.safeLane, this.blocked, this.stagger);
  final double offset, stagger;
  final int safeLane;
  final List<int> blocked;
  double get end => offset + stagger;
}

/// Stable across Dart VM and JavaScript so friend challenges share a course.
class CourseRandom implements Random {
  CourseRandom(int seed) : _state = seed % 2147483646 + 1;
  int _state;
  @override
  double nextDouble() {
    _state = (_state * 48271) % 2147483647;
    return (_state - 1) / 2147483646;
  }

  @override
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max);
    return (nextDouble() * max).floor();
  }

  @override
  bool nextBool() => nextInt(2) == 0;
}

/// Produces varied sequences, not an endless repeating row cadence.
/// Gaps cover worst-case wet/oil steering even at boosted speed. Long lateral
/// crossings receive extra clearance; staggered tails cannot close the route.
class SpawnManager {
  SpawnManager({Random? random}) : random = random ?? Random();
  Random random;
  int safeLane = 1;
  RoadPattern pattern = RoadPattern.single;
  List<RoadBeat> beats = [];
  double _spacing = 800;
  int _untilBreather = 4;
  void reset({int? seed}) {
    if (seed != null) random = CourseRandom(seed);
    safeLane = 1;
    beats = [];
    pattern = RoadPattern.single;
    _spacing = 800;
    _untilBreather = 4 + random.nextInt(4);
  }

  double speedAt(double meters) {
    if (meters < 1000) return 340 + max(0, meters) * .20;
    return min(740, 540 + (meters - 1000) * .10);
  }

  static double clearanceSeconds(int laneDelta) => switch (laneDelta.abs()) {
    0 => .38,
    1 => .72,
    _ => 1.14,
  };

  // Budget at the speed the player can reach by the end of the whole sequence.
  double planningSpeed(double meters) =>
      speedAt(meters + 600) * GameConfig.boostMultiplier;
  double rowSpacingAt(double meters) => _spacing;

  List<RoadItem> nextRow(double meters) {
    final pool = meters < 300
        ? [RoadPattern.single]
        : meters < 1000
        ? [RoadPattern.single, RoadPattern.gates, RoadPattern.stagger]
        : meters < 3000
        ? [
            RoadPattern.single,
            RoadPattern.gates,
            RoadPattern.hold,
            RoadPattern.stagger,
            RoadPattern.slalom,
          ]
        : [
            RoadPattern.single,
            RoadPattern.gates,
            RoadPattern.hold,
            RoadPattern.stagger,
            RoadPattern.slalom,
            RoadPattern.crossing,
            RoadPattern.stagger,
            RoadPattern.slalom,
          ];
    final choices = pool.where((p) => p != pattern).toList();
    pattern = choices.isEmpty
        ? pool.first
        : choices[random.nextInt(choices.length)];
    final length = switch (pattern) {
      RoadPattern.single => 1,
      RoadPattern.gates || RoadPattern.crossing => 2,
      _ => meters >= 6000 ? 3 + random.nextInt(2) : 3,
    };
    final speed = planningSpeed(meters);
    final previousSafe = safeLane;
    double offset = 0;
    beats = [];
    for (int i = 0; i < length; i++) {
      final before = safeLane;
      final candidates = [
        before,
        if (before > 0) before - 1,
        if (before < 2) before + 1,
      ];
      if (i == 0) {
        safeLane = candidates[random.nextInt(candidates.length)];
        if (pattern == RoadPattern.crossing && before == 1) {
          safeLane = random.nextBool() ? 0 : 2;
        }
      } else if (pattern == RoadPattern.hold && i < length - 1) {
        safeLane = before;
      } else if (pattern == RoadPattern.crossing && before != 1) {
        safeLane = 2 - before;
      } else {
        safeLane = candidates[random.nextInt(candidates.length)];
      }
      if (i > 0) {
        final minimum = clearanceSeconds(safeLane - before);
        final variation = meters >= 10000
            ? .20
            : meters >= 3000
            ? .35
            : .55;
        offset =
            beats.last.end +
            speed * (minimum + random.nextDouble() * variation);
      }
      final blocked = [0, 1, 2]..remove(safeLane);
      blocked.shuffle(random);
      final count =
          pattern == RoadPattern.single ||
              meters < 300 ||
              (i == 0 &&
                  (pattern == RoadPattern.gates ||
                      pattern == RoadPattern.crossing))
          ? 1
          : 2;
      final stagger = pattern == RoadPattern.stagger
          ? 60 + random.nextDouble() * 100
          : 0.0;
      beats.add(
        RoadBeat(offset, safeLane, blocked.take(count).toList(), stagger),
      );
    }
    final breather = --_untilBreather <= 0;
    if (breather) _untilBreather = 4 + random.nextInt(4);
    final exitSeconds = meters < 300
        ? 1.4 + random.nextDouble() * .9
        : .72 +
              random.nextDouble() * (breather ? 1.1 : .55) +
              (breather ? .35 : 0);
    _spacing = beats.last.end + speed * exitSeconds;

    final items = <RoadItem>[];
    for (int i = 0; i < beats.length; i++) {
      final beat = beats[i];
      for (final (index, lane) in beat.blocked.indexed) {
        items.add(
          RoadItem(
            kind: meters < 160
                ? ItemKind.pothole
                : index == 0
                ? [ItemKind.pothole, ItemKind.barricade][random.nextInt(2)]
                : [ItemKind.pothole, ItemKind.barricade, ItemKind.oil][random
                      .nextInt(3)],
            lane: lane,
            y: -70 - beat.offset - (index == 0 ? 0 : beat.stagger),
            radius: 22 + random.nextDouble() * 9,
            variant: random.nextInt(3),
          ),
        );
      }
      // No guaranteed breadcrumb trail. Optional detours only appear when the
      // reserved gaps permit reaching them AND returning to the next safe lane.
      if (random.nextDouble() > .45) continue;
      final from = i == 0 ? previousSafe : beats[i - 1].safeLane;
      final availableBefore = i == 0
          ? .72
          : (beat.offset - beats[i - 1].end) / speed;
      final to = i == beats.length - 1 ? beat.safeLane : beats[i + 1].safeLane;
      final availableAfter = i == beats.length - 1
          ? 0.0
          : (beats[i + 1].offset - beat.end) / speed;
      final rewardLanes = [0, 1, 2]
          .where(
            (lane) =>
                !beat.blocked.contains(lane) &&
                clearanceSeconds(lane - from) <= availableBefore + .000001 &&
                (i == beats.length - 1
                    ? lane == beat.safeLane
                    : clearanceSeconds(to - lane) <= availableAfter + .000001),
          )
          .toList();
      if (rewardLanes.isEmpty) continue;
      final rewardLane = rewardLanes[random.nextInt(rewardLanes.length)];
      items.add(
        RoadItem(
          kind: random.nextBool() ? ItemKind.coin : ItemKind.passenger,
          lane: rewardLane,
          y: -70 - beat.offset,
          radius: 14,
        ),
      );
    }
    return items;
  }

  static double laneX(int lane) => GameConfig.laneX(lane);
}
