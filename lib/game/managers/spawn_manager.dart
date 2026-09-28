import 'dart:math';
import '../game_config.dart';
import '../game_state.dart';

/// Rows always have a safe corridor. The corridor shifts at most one lane
/// between rows, with enough separation even at maximum boosted speed.
class SpawnManager {
  SpawnManager({Random? random}) : random = random ?? Random();
  final Random random;
  double timer = 1.8;
  int safeLane = 1;
  void reset() {
    timer = 1.8;
    safeLane = 1;
  }

  double intervalAt(double seconds) => 1.5 - 1.1 * (seconds / 60).clamp(0, 1);
  double speedAt(double seconds) => min(520, 260 + seconds * 4);
  double rowSpacingAt(double seconds) {
    // A 0.4-second row gap is unsafe at 2x speed. Preserve at least 0.68s
    // between row centers at the fastest possible speed, including boost.
    return max(speedAt(seconds) * intervalAt(seconds), 520 * 2 * 0.68);
  }

  List<RoadItem> nextRow(double seconds) {
    final options = [
      safeLane,
      if (safeLane > 0) safeLane - 1,
      if (safeLane < 2) safeLane + 1,
    ];
    safeLane = options[random.nextInt(options.length)];
    final blocked = [0, 1, 2]..remove(safeLane);
    blocked.shuffle(random);
    final count = seconds < 15 ? 1 : (random.nextDouble() < 0.7 ? 2 : 1);
    return [
      for (final lane in blocked.take(count))
        RoadItem(
          kind: ItemKind.pothole,
          lane: lane,
          y: -70,
          radius: 22 + random.nextDouble() * 9,
          variant: random.nextInt(3),
        ),
      if (random.nextDouble() < 0.8)
        RoadItem(kind: ItemKind.passenger, lane: safeLane, y: -70, radius: 16),
    ];
  }

  static double laneX(int lane) => GameConfig.laneX(lane);
}
