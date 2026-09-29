import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/main.dart';
import 'package:pothole_panic/game/friend_challenge.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/pothole_game.dart';
import 'package:pothole_panic/game/vehicle.dart';
import 'package:pothole_panic/services/save_service.dart';
import 'game_flow_test.dart' show SilentAudio;

void main() {
  testWidgets(
    'Create, finish, copy, persist, join, compare and retry a friend road',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      SharedPreferences.setMockInitialValues({});
      final save = SaveService(await SharedPreferences.getInstance());
      await save.creditCoins(100);
      await save.selectOrUnlock(Vehicle.car);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(save: save, audioOverride: SilentAudio()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      Future<void> tap(String text) async {
        await tester.ensureVisible(find.text(text));
        await tester.tap(find.text(text));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tap('FRIEND CHALLENGE');
      await tap('PLAY FRIEND’S ROAD');
      expect(
        find.text('Enter a Pothole Panic challenge code or invite.'),
        findsOneWidget,
      );
      await tap('SET A SCORE');
      final game = tester
          .widget<GameWidget<PotholeGame>>(find.byType(GameWidget<PotholeGame>))
          .game!;
      expect(game.model.vehicle, Vehicle.auto);
      expect(game.model.competitive, isTrue);
      final seed = game.model.courseSeed;
      game.model.distance = 8000;
      game.model.health = 0;
      game.model.phase = GamePhase.dying;
      game.model.deathTime = .64;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('YOUR CHALLENGE IS READY'), findsOneWidget);
      expect(find.text('ONE MORE CHANCE'), findsNothing);
      await tap('COPY INVITE');
      final invite = FriendChallenge.parse(clipboard!);
      expect(invite.seed, seed);
      expect(invite.targetScore, 800);
      expect(save.lastChallenge!.code, invite.code);
      await tap('BACK TO THE GARAGE');
      await tap('FRIEND CHALLENGE');
      expect(find.text('YOUR LAST CHALLENGE · 800 POINTS'), findsOneWidget);
      await tester.enterText(find.byType(TextField), clipboard!);
      await tap('PLAY FRIEND’S ROAD');
      expect(game.model.courseSeed, seed);
      expect(game.model.challengeTarget, 800);
      game.model.distance = 9000;
      game.model.health = 0;
      game.model.phase = GamePhase.dying;
      game.model.deathTime = .64;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      expect(find.text('YOU BEAT YOUR FRIEND!'), findsOneWidget);
      await tap('RETRY THIS ROAD');
      expect(game.model.courseSeed, seed);
      expect(game.model.challengeTarget, 800);
      game.pauseRun();
      await tester.pump();
      await tap('END RUN & GO HOME');
      await tap('CHALO! LET’S RIDE');
      expect(game.model.competitive, isFalse);
      expect(game.model.vehicle, Vehicle.car);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('Invite links open the challenge panel without auto-starting', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    SharedPreferences.setMockInitialValues({});
    const invite = FriendChallenge(seed: 123, targetScore: 500);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          save: SaveService(await SharedPreferences.getInstance()),
          audioOverride: SilentAudio(),
          initialInvite: invite.code,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      invite.code,
    );
    final game = tester
        .widget<GameWidget<PotholeGame>>(find.byType(GameWidget<PotholeGame>))
        .game!;
    expect(game.model.phase, GamePhase.menu);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
