import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothole_panic/ui/main_menu.dart';
import 'package:pothole_panic/ui/game_over.dart';
import 'package:pothole_panic/game/run_model.dart';

void main() {
  testWidgets('Menu fits a small phone and its start button works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MainMenu(
            best: 123,
            onStart: () => started = true,
            onHelp: () {},
            onSound: () {},
            sound: false,
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('CHALO! LET’S RIDE'));
    await tester.tap(find.text('CHALO! LET’S RIDE'));
    expect(started, true);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Unavailable reward offers retry and retains restart', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameOver(
            model: RunModel(),
            best: 0,
            onRetry: () {},
            onHome: () {},
            onContinue: () {},
            canContinue: true,
            busy: false,
            browser: false,
            rewardLoading: false,
            rewardAvailable: false,
            onLoadReward: () {},
          ),
        ),
      ),
    );
    expect(find.text('RETRY AD CONNECTION'), findsOneWidget);
    expect(find.text('ANOTHER ROUND'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
