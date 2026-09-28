import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/main.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/managers/audio_manager.dart';
import 'package:pothole_panic/services/save_service.dart';

class SilentAudio extends Fake implements AudioManager {
  @override
  bool enabled = false;
  @override
  Future<void> setRunning(bool running) async {}
  @override
  void play(GameEvent event) {}
  @override
  Future<void> toggle(bool value) async {
    enabled = value;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('Full screen: start, steer, horn, pause, resume, quit, save', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final save = SaveService(prefs);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(save: save, audioOverride: SilentAudio()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('CHALO! LET’S RIDE'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('METER RUNNING'), findsOneWidget);
    await tester.tap(find.byTooltip('Move right'));
    await tester.tap(find.text('HORN!'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Pause game'));
    await tester.pump();
    expect(find.text('CHAI BREAK'), findsOneWidget);
    await tester.tap(find.text('BACK TO THE ROAD'));
    await tester.pump();
    expect(find.text('METER RUNNING'), findsOneWidget);
    await tester.tap(find.byTooltip('Pause game'));
    await tester.pump();
    await tester.tap(find.text('END RUN & GO HOME'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('CHALO! LET’S RIDE'), findsOneWidget);
    expect(save.runs, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
