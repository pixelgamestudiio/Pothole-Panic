import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../game_state.dart';

class AudioManager {
  AudioManager({required this.enabled});
  bool enabled;
  final _effects = List.generate(4, (_) => AudioPlayer());
  final _ambience = AudioPlayer();
  int _next = 0;
  bool _running = false;
  Future<void> setRunning(bool running) async {
    if (_running == running) return;
    _running = running;
    try {
      if (running && enabled) {
        await _ambience.setReleaseMode(ReleaseMode.loop);
        await _ambience.play(AssetSource('audio/background.wav'), volume: 0.16);
      } else {
        await _ambience.stop();
      }
    } catch (_) {
      /* Audio must never block gameplay, including browser autoplay. */
    }
  }

  Future<void> toggle(bool value) async {
    enabled = value;
    final running = _running;
    _running = false;
    if (!value) {
      await _ambience.stop();
      for (final player in _effects) {
        await player.stop();
      }
    } else if (running) {
      await setRunning(true);
    }
  }

  void play(GameEvent event) {
    if (!enabled) return;
    final name = switch (event) {
      GameEvent.pickup => 'pickup',
      GameEvent.horn => 'horn',
      GameEvent.crash => 'hit_pothole',
      GameEvent.nearMiss => 'near_miss',
      GameEvent.revive => 'pickup',
    };
    final player = _effects[_next++ % _effects.length];
    unawaited(_play(player, name));
  }

  Future<void> _play(AudioPlayer player, String name) async {
    try {
      await player.stop();
      await player.play(AssetSource('audio/$name.wav'), volume: 0.55);
    } catch (_) {
      /* Missing audio hardware is non-fatal. */
    }
  }

  Future<void> dispose() async {
    await _ambience.dispose();
    for (final player in _effects) {
      await player.dispose();
    }
  }
}
