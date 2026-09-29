import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'components/auto_rickshaw.dart';
import 'components/hud.dart';
import 'components/road.dart';
import 'components/weather.dart';
import 'game_config.dart';
import 'game_state.dart';
import 'managers/audio_manager.dart';
import 'run_model.dart';
import 'friend_challenge.dart';

class PotholeGame extends FlameGame {
  PotholeGame({
    required this.audio,
    required this.onRunEnded,
    this.onCoinsEarned,
  }) : super(
         camera: CameraComponent.withFixedResolution(
           width: GameConfig.width,
           height: GameConfig.height,
         ),
       );
  final RunModel model = RunModel();
  final AudioManager audio;
  final VoidCallback onRunEnded;
  final ValueChanged<int>? onCoinsEarned;
  final ValueNotifier<int> revision = ValueNotifier(0);
  double _accumulator = 0, _uiClock = 0;
  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    await world.addAll([
      Road(model),
      RoadLighting(model),
      RoadObjects(model),
      AutoRickshaw(model),
      Weather(model),
      FloatingHud(model),
    ]);
  }

  void refresh() {
    revision.value++;
  }

  void startRun({FriendChallenge? challenge}) {
    model.start(
      seed: challenge?.seed,
      challenge: challenge != null,
      targetScore: challenge?.targetScore ?? 0,
    );
    _accumulator = 0;
    refresh();
  }

  void pauseRun() {
    model.pause();
    audio.setRunning(false);
    refresh();
  }

  void resumeRun() {
    model.resume();
    _accumulator = 0;
    refresh();
  }

  void menu() {
    model.phase = GamePhase.menu;
    model.items.clear();
    model.labels.clear();
    refresh();
  }

  void steer(int direction) {
    model.switchLane(direction);
  }

  void horn() {
    model.horn();
  }

  @override
  void update(double dt) {
    final before = model.phase;
    final coinsBefore = model.coins;
    _accumulator += dt.clamp(0.0, 0.25);
    while (_accumulator >= GameConfig.fixedStep) {
      model.step(GameConfig.fixedStep);
      _accumulator -= GameConfig.fixedStep;
    }
    for (final event in model.events) {
      audio.play(event);
    }
    model.events.clear();
    if (model.coins > coinsBefore) {
      onCoinsEarned?.call(model.coins - coinsBefore);
    }
    audio.setRunning(model.phase == GamePhase.playing);
    audio.setWeather(model.rain);
    if (before != GamePhase.gameOver && model.phase == GamePhase.gameOver) {
      onRunEnded();
    }
    if (model.phase == GamePhase.dying) {
      final amount = (1 - model.deathTime / 0.65) * 4;
      camera.viewfinder.position = Vector2(
        sin(model.deathTime * 99) * amount,
        cos(model.deathTime * 113) * amount,
      );
    } else {
      camera.viewfinder.position = Vector2.zero();
    }
    _uiClock += dt;
    if (_uiClock > 0.05 || before != model.phase) {
      _uiClock = 0;
      refresh();
    }
    super.update(dt);
  }
}
