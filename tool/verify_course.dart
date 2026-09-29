// Run using Dart VM and compiled JavaScript; the JSON fingerprints must match.
import 'dart:convert';
import 'package:pothole_panic/game/friend_challenge.dart';
import 'package:pothole_panic/game/run_model.dart';

void main() {
  final model = RunModel()..start(seed: 123456789, challenge: true);
  model.protection = 100000;
  var seen = model.spawner.beats;
  int sections = 0, fingerprint = 17;
  while (sections < 120) {
    if (model.cooldown == 0) model.horn();
    model.step(1 / 120);
    if (!identical(seen, model.spawner.beats)) {
      seen = model.spawner.beats;
      final text = jsonEncode([
        model.spawner.pattern.name,
        (model.spawner.rowSpacingAt(model.meters) * 1000).round(),
        seen
            .map(
              (b) => [
                (b.offset * 1000).round(),
                (b.stagger * 1000).round(),
                b.safeLane,
                b.blocked,
              ],
            )
            .toList(),
      ]);
      for (final c in text.codeUnits) {
        fingerprint = (fingerprint * 31 + c) % 2147483647;
      }
      sections++;
    }
  }
  // CLI verifier deliberately emits machine-readable output on both runtimes.
  // ignore: avoid_print
  print(
    jsonEncode({
      'sections': sections,
      'fingerprint': fingerprint,
      'invite': const FriendChallenge(seed: 123456789, targetScore: 16719).code,
    }),
  );
}
