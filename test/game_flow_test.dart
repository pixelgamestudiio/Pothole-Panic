import 'package:flutter/foundation.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/main.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/pothole_game.dart';
import 'package:pothole_panic/game/vehicle.dart';
import 'package:pothole_panic/game/road_environment.dart';
import 'package:pothole_panic/game/managers/audio_manager.dart';
import 'package:pothole_panic/services/save_service.dart';

class SilentAudio extends Fake implements AudioManager {
  @override
  bool enabled = false;
  @override
  Future<void> setRunning(bool running) async {}
  @override
  Future<void> setWeather(double intensity) async {}
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
    await save.creditCoins(100);
    await save.selectOrUnlock(Vehicle.car);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(save: save, audioOverride: SilentAudio()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // The root keyboard handler must not turn menu Enter into a new run.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('CHALO! LET’S RIDE'), findsOneWidget);
    await tester.ensureVisible(find.text('GARAGE · 0 COINS'));
    await tester.tap(find.text('GARAGE · 0 COINS'));
    await tester.pump();
    expect(find.text('YOUR GARAGE'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('YOUR GARAGE'), findsNothing);
    expect(find.text('TIME OF DAY'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'NIGHT'), findsNothing);
    await tester.ensureVisible(find.text('CHALO! LET’S RIDE'));
    await tester.tap(find.text('CHALO! LET’S RIDE'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('METER RUNNING'), findsOneWidget);
    final game = tester
        .widget<GameWidget<PotholeGame>>(find.byType(GameWidget<PotholeGame>))
        .game!;
    expect(game.model.vehicle, Vehicle.car);
    expect(game.model.daylight, Daylight.day);
    game.model.items.add(RoadItem(kind: ItemKind.coin, lane: 1, y: 590));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(save.coins, 5);
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
    expect(
      save.coins,
      5,
    ); // Ending the run must not bank the coins a second time.
    await tester.tap(find.text('CHALO! LET’S RIDE'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.model.coins, 0);
    expect(save.coins, 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
