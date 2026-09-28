enum GamePhase { menu, playing, paused, dying, gameOver }

enum GameEvent { pickup, horn, crash, nearMiss, revive }

enum ItemKind { pothole, passenger }

class RoadItem {
  RoadItem({
    required this.kind,
    required this.lane,
    required this.y,
    this.radius = 23,
    this.variant = 0,
  });
  final ItemKind kind;
  final int lane;
  final double radius;
  final int variant;
  double y;
  bool passed = false;
  bool collected = false;
}

class FloatingLabel {
  FloatingLabel(this.text, this.x, this.y, {this.life = 1});
  final String text;
  final double x;
  double y;
  double life;
}
