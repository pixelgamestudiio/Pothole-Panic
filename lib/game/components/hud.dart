import 'dart:ui';
import 'package:flame/components.dart';
import '../game_config.dart';
import '../game_state.dart';
import '../run_model.dart';
import 'palette.dart';
import 'passenger.dart';
import 'pothole.dart';

class RoadObjects extends Component {
  RoadObjects(this.model) : super(priority: 2);
  final RunModel model;
  @override
  void render(Canvas canvas) {
    for (final item in model.items) {
      final x = GameConfig.laneX(item.lane);
      if (item.kind == ItemKind.pothole) {
        paintPothole(canvas, x, item.y, item.radius, item.variant);
      } else {
        paintPassenger(canvas, x, item.y, model.elapsed);
      }
    }
  }
}

class FloatingHud extends Component {
  FloatingHud(this.model) : super(priority: 5);
  final RunModel model;
  @override
  void render(Canvas canvas) {
    for (final label in model.labels) {
      drawLabel(
        canvas,
        label.text,
        Offset(label.x.clamp(115, 305), label.y),
        size: 16,
        color: Palette.cream.withValues(alpha: label.life.clamp(0, 1)),
      );
    }
  }
}
