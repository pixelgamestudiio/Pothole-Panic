import 'dart:math';
import 'game_config.dart';
import 'game_state.dart';
import 'managers/collision_manager.dart';
import 'managers/spawn_manager.dart';

/// Engine-independent simulation; all timers advance only through step().
class RunModel {
  RunModel({Random? random}) : spawner = SpawnManager(random: random);
  final SpawnManager spawner;
  final List<RoadItem> items = [];
  final List<FloatingLabel> labels = [];
  final List<GameEvent> events = [];
  GamePhase phase = GamePhase.menu;
  double elapsed = 0, distance = 0, scroll = 0;
  double playerX = GameConfig.laneX(1), fromX = GameConfig.laneX(1);
  double laneProgress = 1, boostLeft = 0, cooldown = 0, protection = 0;
  double deathTime = 0, nearMissCooldown = 0, nextRowDistance = 380;
  int lane = 1, fare = 0, passengers = 0, nearMisses = 0;
  bool continued = false;
  int get score => (distance / 10).floor() + fare + nearMisses * 5;
  double get speed => spawner.speedAt(elapsed) * (boostLeft > 0 ? 2 : 1);
  bool get shielded => boostLeft > 0 || protection > 0;
  String get district => elapsed < 25
      ? 'BAZAAR ROAD'
      : elapsed < 55
      ? 'RUSH HOUR'
      : 'MONSOON MILE';

  void start() {
    phase = GamePhase.playing;
    elapsed = distance = scroll = boostLeft = cooldown = protection =
        deathTime = 0;
    fare = passengers = nearMisses = 0;
    continued = false;
    lane = 1;
    playerX = fromX = GameConfig.laneX(1);
    laneProgress = 1;
    nearMissCooldown = 0;
    nextRowDistance = 380;
    items.clear();
    labels.clear();
    events.clear();
    spawner.reset();
  }

  void switchLane(int direction) {
    if (phase != GamePhase.playing || direction == 0) return;
    final target = (lane + direction.sign).clamp(0, 2);
    if (target == lane) return;
    fromX = playerX;
    lane = target;
    laneProgress = 0;
  }

  bool horn() {
    if (phase != GamePhase.playing || cooldown > 0) return false;
    boostLeft = GameConfig.boostSeconds;
    cooldown = GameConfig.boostCooldown;
    events.add(GameEvent.horn);
    labels.add(FloatingLabel('CHALO CHALO!  2× FARE', playerX, 510));
    return true;
  }

  void pause() {
    if (phase == GamePhase.playing) phase = GamePhase.paused;
  }

  void resume() {
    if (phase == GamePhase.paused) phase = GamePhase.playing;
  }

  bool revive() {
    if (phase != GamePhase.gameOver || continued) return false;
    continued = true;
    protection = 2.5;
    boostLeft = 0;
    cooldown = 0;
    items.removeWhere((e) => e.y > 160);
    nextRowDistance = max(nextRowDistance, 350);
    phase = GamePhase.playing;
    deathTime = 0;
    events.add(GameEvent.revive);
    return true;
  }

  void step(double dt) {
    if (phase == GamePhase.menu) {
      scroll += 65 * dt;
      return;
    }
    if (phase == GamePhase.dying) {
      deathTime += dt;
      if (deathTime >= 0.65) phase = GamePhase.gameOver;
      return;
    }
    if (phase != GamePhase.playing) return;
    final oldX = playerX;
    laneProgress = min(1, laneProgress + dt / GameConfig.laneChangeSeconds);
    final t = 1 - pow(1 - laneProgress, 3);
    playerX = fromX + (GameConfig.laneX(lane) - fromX) * t;
    final travel = speed * dt;
    distance += travel;
    scroll += travel;
    elapsed += dt;
    nextRowDistance -= travel;
    if (nextRowDistance <= 0) {
      items.addAll(spawner.nextRow(elapsed));
      nextRowDistance += spawner.rowSpacingAt(elapsed);
    }
    for (final item in items) {
      final oldY = item.y;
      item.y += travel;
      if (item.collected) continue;
      if (CollisionManager.intersects(item, oldY, oldX, playerX)) {
        if (item.kind == ItemKind.passenger) {
          item.collected = true;
          final reward = boostLeft > 0 ? 20 : 10;
          fare += reward;
          passengers++;
          labels.add(
            FloatingLabel(
              '+₹$reward',
              GameConfig.laneX(item.lane),
              item.y - 40,
            ),
          );
          events.add(GameEvent.pickup);
        } else if (shielded) {
          item.collected = true;
        } else {
          phase = GamePhase.dying;
          deathTime = 0;
          events.add(GameEvent.crash);
          break;
        }
      }
      if (item.kind == ItemKind.pothole &&
          !item.passed &&
          item.y > GameConfig.playerY + 56) {
        item.passed = true;
        final gap = (GameConfig.laneX(item.lane) - playerX).abs();
        if (!shielded && gap < 83 && gap > 44 && nearMissCooldown <= 0) {
          nearMisses++;
          nearMissCooldown = 1;
          labels.add(FloatingLabel('BACH GAYE! +5', playerX, 535));
          events.add(GameEvent.nearMiss);
        }
      }
    }
    items.removeWhere((e) => e.collected || e.y > GameConfig.height + 100);
    boostLeft = max(0, boostLeft - dt);
    cooldown = max(0, cooldown - dt);
    protection = max(0, protection - dt);
    nearMissCooldown = max(0, nearMissCooldown - dt);
    for (final label in labels) {
      label.life -= dt;
      label.y -= 24 * dt;
    }
    labels.removeWhere((e) => e.life <= 0);
  }
}
