import 'dart:math';
import '../game_config.dart';
import '../game_state.dart';

abstract final class CollisionManager {
  /// Swept relative-motion AABB. Handles simultaneous lane changes and fast
  /// scrolling without allowing objects to tunnel between frames.
  static bool intersects(
    RoadItem item,
    double oldY,
    double oldPlayerX,
    double newPlayerX,
  ) {
    final halfY = item.kind == ItemKind.pothole ? item.radius * 0.55 : 16.0;
    final halfX = item.kind == ItemKind.pothole ? item.radius * 0.8 : 15.0;
    final x = GameConfig.laneX(item.lane) - oldPlayerX;
    final y = oldY - GameConfig.playerY;
    final dx = oldPlayerX - newPlayerX;
    final dy = item.y - oldY;
    double enter = 0, leave = 1;
    final axes = [
      (x, dx, halfX + GameConfig.playerHalfWidth),
      (y, dy, halfY + GameConfig.playerHalfHeight),
    ];
    for (final (p, d, extent) in axes) {
      if (d.abs() < 1e-9) {
        if (p.abs() > extent) return false;
      } else {
        final a = (-extent - p) / d, b = (extent - p) / d;
        enter = max(enter, min(a, b));
        leave = min(leave, max(a, b));
        if (enter > leave) return false;
      }
    }
    return true;
  }
}
