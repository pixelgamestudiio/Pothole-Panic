import 'dart:math';
import 'game_config.dart';
import 'game_state.dart';
import 'managers/collision_manager.dart';
import 'managers/spawn_manager.dart';
import 'vehicle.dart';
import 'road_environment.dart';

/// Engine-independent simulation; all timers advance only through step().
class RunModel {
  RunModel({Random? random})
    : _seedSource = random ?? Random(),
      spawner = SpawnManager(random: random);
  final Random _seedSource;
  int courseSeed = 1;
  bool competitive = false;
  int challengeTarget = 0;
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
  Vehicle vehicle = Vehicle.auto;
  int health = 3, coins = 0;
  double skidLeft = 0, skidOffset = 0;
  ItemKind? lastCrash;
  // A 2 km cycle: day 0–500 m, afternoon 500–1,000 m, night 1,000–2,000 m.
  // Each transition blends over the final 100 m instead of flashing abruptly.
  double get lightCycle => meters % 2000;
  Daylight get daylight => lightCycle < 500
      ? Daylight.day
      : lightCycle < 1000
      ? Daylight.afternoon
      : Daylight.night;
  Daylight get nextDaylight => Daylight.values[(daylight.index + 1) % 3];
  double get lightBlend {
    final boundary = lightCycle < 500
        ? 500
        : lightCycle < 1000
        ? 1000
        : 2000;
    return ((lightCycle - boundary + 100) / 100).clamp(0, 1);
  }

  double lightWeight(Daylight value) =>
      (daylight == value ? 1 - lightBlend : 0) +
      (nextDaylight == value ? lightBlend : 0);
  double get meters => distance / 10;
  Difficulty get difficulty => Difficulty.at(meters);
  double get stageProgress => switch (difficulty) {
    Difficulty.easy => meters / 500,
    Difficulty.medium => (meters - 500) / 500,
    Difficulty.hard => 1,
  };
  double stageBannerLeft = 0;
  // Clear skies, a five-second transition, monsoon, then a gradual clearing.
  double get rain {
    final t = (competitive ? meters / 40 : elapsed) % 70;
    if (t < 25) return 0;
    if (t < 30) return (t - 25) / 5;
    if (t < 55) return 1;
    return 1 - (t - 55) / 15;
  }

  String get conditions =>
      rain > 0.15 ? 'RAIN · WET ROAD' : '${daylight.label} · DRY ROAD';
  double get steeringSeconds => min(
    0.38,
    vehicle.laneSeconds *
        (1 + rain * 0.2 * vehicle.slipFactor) *
        (skidLeft > 0 ? 1.6 : 1),
  );
  int get score => (distance / 10).floor() + fare + nearMisses * 5;
  double get speed =>
      spawner.speedAt(meters) *
      (boostLeft > 0 ? GameConfig.boostMultiplier : 1) *
      (1 - rain * 0.1);
  bool get shielded => boostLeft > 0 || protection > 0;
  String get district => District.at(meters).label;

  void start({
    Vehicle? selectedVehicle,
    int? seed,
    bool challenge = false,
    int targetScore = 0,
  }) {
    competitive = challenge;
    challengeTarget = targetScore;
    courseSeed = seed ?? _seedSource.nextInt(2147483646);
    vehicle = challenge ? Vehicle.auto : selectedVehicle ?? vehicle;
    phase = GamePhase.playing;
    elapsed = distance = scroll = boostLeft = cooldown = protection =
        deathTime = 0;
    fare = passengers = nearMisses = 0;
    health = 3;
    coins = 0;
    skidLeft = skidOffset = 0;
    lastCrash = null;
    stageBannerLeft = 0;
    continued = false;
    lane = 1;
    playerX = fromX = GameConfig.laneX(1);
    laneProgress = 1;
    nearMissCooldown = 0;
    nextRowDistance = 380;
    items.clear();
    labels.clear();
    events.clear();
    spawner.reset(seed: courseSeed);
  }

  void switchLane(int direction) {
    if (phase != GamePhase.playing || direction == 0) return;
    final target = (lane + direction.sign).clamp(0, 2);
    if (target == lane) return;
    fromX = playerX - skidOffset;
    lane = target;
    laneProgress = 0;
  }

  bool horn() {
    if (phase != GamePhase.playing || cooldown > 0) return false;
    boostLeft = GameConfig.boostSeconds;
    _clearRoadEffects();
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
    if (phase != GamePhase.gameOver || continued || competitive) return false;
    continued = true;
    health = 3;
    _clearRoadEffects();
    protection = 2.5;
    boostLeft = 0;
    items.removeWhere((e) => e.y > 160);
    nextRowDistance = max(nextRowDistance, 350);
    phase = GamePhase.playing;
    deathTime = 0;
    events.add(GameEvent.revive);
    return true;
  }

  void _clearRoadEffects() {
    skidLeft = 0;
    // Rebase the curve so clearing a skid never teleports the vehicle.
    fromX = playerX;
    laneProgress = 0;
    skidOffset = 0;
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
    final previousDifficulty = difficulty;
    stageBannerLeft = max(0, stageBannerLeft - dt);
    skidLeft = max(0, skidLeft - dt);
    laneProgress = min(1, laneProgress + dt / steeringSeconds);
    final t = 1 - pow(1 - laneProgress, 3);
    // One second of visible counter-steer wobble, strongest mid-skid. Input
    // remains available, but grip is reduced; no fall or random lane teleport.
    final skidTime = 1 - skidLeft;
    final desiredDrift = skidLeft > 0
        ? sin(skidTime * pi * 4) *
              sin(skidTime * pi) *
              min(32, 28 * vehicle.slipFactor * (1 + rain * .15))
        : 0.0;
    skidOffset += (desiredDrift - skidOffset) * min(1, dt * 12);
    playerX = (fromX + (GameConfig.laneX(lane) - fromX) * t + skidOffset).clamp(
      GameConfig.laneX(0) - 32,
      GameConfig.laneX(2) + 32,
    );
    final travel = speed * dt;
    distance += travel;
    if (difficulty != previousDifficulty) stageBannerLeft = 3;
    scroll += travel;
    elapsed += dt;
    nextRowDistance -= travel;
    if (nextRowDistance <= 0) {
      final overshoot = -nextRowDistance;
      // Plan against the exact course checkpoint, independent of horn use or
      // render frames. Correct new item positions for this step's overshoot.
      final courseMeters = ((distance - overshoot) * 100000).round() / 1000000;
      final sequence = spawner.nextRow(courseMeters);
      for (final item in sequence) {
        item.y += overshoot - travel;
      }
      items.addAll(sequence);
      nextRowDistance += spawner.rowSpacingAt(courseMeters);
    }
    for (final item in items) {
      final oldY = item.y;
      item.y += travel;
      if (item.collected) continue;
      if (CollisionManager.intersects(
        item,
        oldY,
        oldX,
        playerX,
        playerHalfWidth: vehicle.halfWidth,
      )) {
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
        } else if (item.kind == ItemKind.coin) {
          item.collected = true;
          coins += 5;
          labels.add(FloatingLabel('+5 COINS', playerX, item.y - 40));
          events.add(GameEvent.coin);
        } else if (shielded) {
          item.collected = true;
        } else if (item.kind == ItemKind.oil) {
          item.collected = true;
          skidLeft = 1;
          labels.add(FloatingLabel('OIL! STEER THROUGH', playerX, 510));
          events.add(GameEvent.skid);
        } else {
          item.collected = true;
          health--;
          _clearRoadEffects();
          if (health == 0) {
            lastCrash = item.kind;
            phase = GamePhase.dying;
            deathTime = 0;
            events.add(GameEvent.crash);
            break;
          }
          protection = 1.25;
          labels.add(FloatingLabel('OUCH! $health / 3 HEALTH', playerX, 510));
          events.add(GameEvent.damage);
        }
      }
      if (item.kind.damages &&
          !item.collected &&
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
