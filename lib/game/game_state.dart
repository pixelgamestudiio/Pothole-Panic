enum GamePhase { menu, playing, paused, dying, gameOver }

enum GameEvent { pickup, horn, crash, nearMiss, revive, damage, skid, coin }

enum ItemKind { pothole, passenger, oil, barricade, coin }

extension ItemKindRules on ItemKind {
  bool get isHazard => this != ItemKind.passenger && this != ItemKind.coin;
  bool get damages => this == ItemKind.pothole || this == ItemKind.barricade;
}

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
