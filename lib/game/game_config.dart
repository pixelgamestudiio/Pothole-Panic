abstract final class GameConfig {
  static const width = 420.0;
  static const height = 800.0;
  static const laneWidth = 96.0;
  static const roadLeft = 66.0;
  static const playerY = 596.0;
  static const playerHalfWidth = 19.0;
  static const playerHalfHeight = 29.0;
  static const laneChangeSeconds = 0.2;
  static const boostSeconds = 1.0;
  static const boostCooldown = 5.0;
  static const fixedStep = 1 / 120;
  static double laneX(int lane) => roadLeft + laneWidth * (lane + 0.5);
}
