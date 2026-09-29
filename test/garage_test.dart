import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pothole_panic/game/vehicle.dart';
import 'package:pothole_panic/services/save_service.dart';
import 'package:pothole_panic/ui/garage.dart';

void main() {
  testWidgets(
    'Small phone garage unlocks once, selects and restores ownership',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final save = SaveService(prefs);
      await save.creditCoins(150);
      bool closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Garage(save: save, onClose: () => closed = true),
          ),
        ),
      );
      final unlock = find.text('UNLOCK · 100 COINS');
      await tester.ensureVisible(unlock);
      await tester.tap(unlock);
      await tester.pumpAndSettle();
      expect(save.coins, 50);
      expect(save.selectedVehicle, Vehicle.car);
      expect(find.text('100 MORE COINS NEEDED'), findsOneWidget);
      await tester.ensureVisible(find.text('SELECT AUTO'));
      await tester.tap(find.text('SELECT AUTO'));
      await tester.pumpAndSettle();
      expect(save.coins, 50);
      expect(SaveService(prefs).selectedVehicle, Vehicle.auto);
      await tester.ensureVisible(find.text('BACK TO THE ROAD'));
      await tester.tap(find.text('BACK TO THE ROAD'));
      expect(closed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
