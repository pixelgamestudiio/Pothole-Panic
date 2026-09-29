enum Daylight {
  day('DAY'),
  afternoon('AFTERNOON'),
  night('NIGHT');

  const Daylight(this.label);
  final String label;
}

enum Difficulty {
  easy('EASY'),
  medium('MEDIUM'),
  hard('HARD');

  const Difficulty(this.label);
  final String label;
  static Difficulty at(double meters) => meters < 500
      ? easy
      : meters < 1000
      ? medium
      : hard;
}

enum District {
  residential('RESIDENTIAL'),
  market('BAZAAR'),
  fields('OPEN ROAD'),
  works('ROADWORKS');

  const District(this.label);
  final String label;
  static District at(double meters) =>
      values[(meters.clamp(0, double.infinity) / 800).floor() % values.length];
}

// Stable world-space variation: a building keeps its appearance as it scrolls
// past. No per-frame random flicker or short repeating strip of scenery.
double sceneryNoise(int index, int salt) {
  var n = (index * 374761393 + salt * 668265263) & 0x7fffffff;
  n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff;
  return (n ^ (n >> 16)) / 0x7fffffff;
}
