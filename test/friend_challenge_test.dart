import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/game/friend_challenge.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/run_model.dart';
import 'package:pothole_panic/game/vehicle.dart';
import 'package:pothole_panic/services/save_service.dart';

void main() {
  test('Codes round-trip from messages, lowercase text and share links', () {
    for (final seed in [0, 1, 42, 2147483645]) {
      final original = FriendChallenge(seed: seed, targetScore: 16719);
      for (final text in [
        original.code,
        original.code.toLowerCase(),
        original.invite(),
        original.invite(publicBase: Uri.parse('https://example.com/play/')),
      ]) {
        final read = FriendChallenge.parse(text);
        expect(read.seed, seed);
        expect(read.targetScore, 16719);
      }
    }
  });
  test('Malformed, incompatible and out-of-range invites are rejected', () {
    final valid = const FriendChallenge(seed: 42, targetScore: 90).code;
    for (final text in [
      '',
      'hello',
      '$valid-corrupt'.replaceFirst('PP2-', 'PP3-'),
      valid.substring(0, valid.length - 1),
      'x' * 4097,
      const FriendChallenge(seed: 2147483647, targetScore: 90).code,
      const FriendChallenge(seed: 1, targetScore: 1000000001).code,
    ]) {
      expect(() => FriendChallenge.parse(text), throwsFormatException);
    }
    expect(FriendChallenge.publicBase('http://127.0.0.1:8765/'), isNull);
    expect(FriendChallenge.publicBase('https://localhost/'), isNull);
    expect(FriendChallenge.publicBase('https://example.com/game/'), isNotNull);
  });
  test('Challenges enforce auto, no rescue and distance-matched weather', () {
    final a = RunModel()
      ..start(
        seed: 72,
        selectedVehicle: Vehicle.bike,
        challenge: true,
        targetScore: 800,
      );
    final b = RunModel()
      ..start(seed: 72, selectedVehicle: Vehicle.car, challenge: true);
    expect(a.vehicle, Vehicle.auto);
    expect(a.challengeTarget, 800);
    a.distance = b.distance = 12000;
    a.elapsed = 15;
    b.elapsed = 50;
    expect(a.rain, b.rain);
    expect(a.daylight, b.daylight);
    a.phase = GamePhase.gameOver;
    expect(a.revive(), isFalse);
    a.start(selectedVehicle: Vehicle.car);
    expect(a.competitive, isFalse);
    expect(a.vehicle, Vehicle.car);
  });
  test(
    'Same seed reproduces the course despite frame rate and horn choices',
    () {
      List<String> trace(int fps, bool horn) {
        final m = RunModel()..start(seed: 98765, challenge: true);
        m.protection = 10000;
        final result = <String>[];
        var seen = m.spawner.beats;
        while (result.length < 80) {
          if (horn && m.cooldown <= 0) m.horn();
          m.step(1 / fps);
          if (!identical(seen, m.spawner.beats)) {
            seen = m.spawner.beats;
            result.add(
              jsonEncode([
                m.spawner.pattern.name,
                m.spawner.rowSpacingAt(m.meters),
                seen
                    .map((b) => [b.offset, b.stagger, b.safeLane, b.blocked])
                    .toList(),
              ]),
            );
          }
        }
        return result;
      }

      final baseline = trace(120, false);
      expect(trace(30, false), baseline);
      expect(trace(60, true), baseline);
      expect(trace(120, true), baseline);
    },
  );
  test(
    'Last completed challenge survives reload; corrupt saves do not break menus',
    () async {
      SharedPreferences.setMockInitialValues({'best': 77});
      final prefs = await SharedPreferences.getInstance();
      final save = SaveService(prefs);
      expect(save.lastChallenge, isNull);
      const challenge = FriendChallenge(seed: 123, targetScore: 500);
      expect(await save.saveChallenge(challenge), isTrue);
      expect(SaveService(prefs).lastChallenge!.code, challenge.code);
      expect(save.best, 77);
      await prefs.setString('last_friend_challenge', 'bad-code');
      expect(SaveService(prefs).lastChallenge, isNull);
    },
  );
}
