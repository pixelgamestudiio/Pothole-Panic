import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../game_state.dart';

class AudioManager {
  AudioManager({required this.enabled});
  bool enabled;
  final _effects = List.generate(4, (_) => AudioPlayer());
  final _ambience = AudioPlayer();
  final _rain = AudioPlayer();
  bool _rainStarted = false, _weatherBusy = false, _disposed = false;
  double _rainVolume = 0, _rainTarget = 0;
  int _next = 0;
  bool _running = false;
  Future<void> setRunning(bool running) async {
    if (_running == running) return;
    _running = running;
    if (!running) await setWeather(0);
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
      await setWeather(0);
      await _ambience.stop();
      for (final player in _effects) {
        await player.stop();
      }
    } else if (running) {
      await setRunning(true);
    }
  }

  Future<void> setWeather(double intensity) async {
    _rainTarget = enabled && _running && !_disposed
        ? intensity.clamp(0, 1) * .55
        : 0;
    if (_weatherBusy || _disposed) return;
    _weatherBusy = true;
    try {
      while (!_disposed && (_rainTarget - _rainVolume).abs() > .02) {
        final target = _rainTarget;
        if (!_rainStarted && target > 0) {
          await _rain.setReleaseMode(ReleaseMode.loop);
          await _rain.play(AssetSource('audio/rain.wav'), volume: target);
          _rainStarted = true;
        } else if (_rainStarted) {
          await _rain.setVolume(target);
        }
        _rainVolume = target;
      }
    } catch (_) {
      // Audio failures must never interrupt the road simulation.
    } finally {
      _weatherBusy = false;
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
      GameEvent.coin => 'pickup',
      GameEvent.damage => 'hit_pothole',
      GameEvent.skid => 'near_miss',
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
    _disposed = true;
    await _rain.dispose();
    await _ambience.dispose();
    for (final player in _effects) {
      await player.dispose();
    }
  }
}
