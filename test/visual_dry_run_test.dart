import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/main.dart';
import 'package:pothole_panic/game/game_state.dart';
import 'package:pothole_panic/game/pothole_game.dart';
import 'package:pothole_panic/game/vehicle.dart';
import 'package:pothole_panic/game/road_environment.dart';
import 'package:pothole_panic/services/save_service.dart';
import 'game_flow_test.dart' show SilentAudio;

// Opt-in screenshots of the actual game screen with controlled dry-run states:
// flutter test test/visual_dry_run_test.dart --dart-define=CAPTURE_DRY_RUN=true
void main() {
  for (final vehicle in Vehicle.values) {
    for (final daylight in Daylight.values) {
      testWidgets(
        '${vehicle.label} / ${daylight.label}: scenery, weather, objects and phone HUD',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.linux;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final font = FontLoader('Bungee')
            ..addFont(rootBundle.load('assets/fonts/Bungee-Regular.ttf'));
          await font.load();
          final icons = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await icons.load();
          // Flutter tests use the square Ahem test font by default. For exported
          // review images only, use an installed sans font for normal UI text.
          if (const bool.fromEnvironment('CAPTURE_DRY_RUN')) {
            final fontPath = Platform.isWindows
                ? 'C:/Windows/Fonts/arial.ttf'
                : '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';
            await tester.runAsync(() async {
              final sans = FontLoader('DryRunSans')
                ..addFont(
                  File(fontPath).readAsBytes().then(ByteData.sublistView),
                );
              await sans.load();
            });
          }
          SharedPreferences.setMockInitialValues({});
          final save = SaveService(await SharedPreferences.getInstance());
          await save.creditCoins(300);
          await save.selectOrUnlock(vehicle);
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: Brightness.dark,
                fontFamily: const bool.fromEnvironment('CAPTURE_DRY_RUN')
                    ? 'DryRunSans'
                    : null,
              ),
              home: RepaintBoundary(
                key: captureKey,
                child: GameScreen(save: save, audioOverride: SilentAudio()),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('CHALO! LET’S RIDE'));
          await tester.pump(const Duration(milliseconds: 100));
          final game = tester
              .widget<GameWidget<PotholeGame>>(
                find.byType(GameWidget<PotholeGame>),
              )
              .game!;
          final model = game.model;
          model.elapsed = daylight == Daylight.day ? 0 : 35;
          model.distance =
              (vehicle.index * 2000.0 + [200, 700, 1400][daylight.index]) * 10;
          model.scroll = model.distance;
          model.nextRowDistance = 10000;
          model.health = 2;
          model.coins = 25;
          model.skidLeft = 1;
          model.items.clear();
          model.items.addAll([
            RoadItem(kind: ItemKind.oil, lane: 0, y: 280, radius: 27),
            RoadItem(kind: ItemKind.barricade, lane: 2, y: 280, radius: 27),
            RoadItem(kind: ItemKind.coin, lane: 1, y: 280),
            RoadItem(kind: ItemKind.barricade, lane: 2, y: 420, radius: 27),
            RoadItem(kind: ItemKind.pothole, lane: 0, y: 420, radius: 27),
            RoadItem(kind: ItemKind.passenger, lane: 1, y: 420),
          ]);
          game.refresh();
          await tester.pump(const Duration(milliseconds: 20));
          await tester.pump();
          expect(model.vehicle, vehicle);
          expect(
            find.text(daylight == Daylight.day ? 'DAY' : 'RAIN'),
            findsOneWidget,
          );
          expect(model.daylight, daylight);
          expect(find.text('OIL SKID · KEEP STEERING'), findsOneWidget);
          expect(tester.takeException(), isNull);

          if (const bool.fromEnvironment('CAPTURE_DRY_RUN')) {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory('outputs').create(recursive: true);
              await File(
                'outputs/dry-run-${vehicle.name}-${daylight.name}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }
}
