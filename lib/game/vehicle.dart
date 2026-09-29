enum Vehicle {
  auto('AUTO', 'The original all-rounder.', 0, 19, 0.20, 1.0),
  car(
    'CITY CAR',
    'More grip on oil. Wider body, slower steering.',
    100,
    25,
    0.25,
    0.6,
  ),
  bike(
    'MOTORBIKE',
    'Narrow and nimble. Slipperier on wet roads.',
    150,
    12,
    0.15,
    1.35,
  );

  const Vehicle(
    this.label,
    this.description,
    this.price,
    this.halfWidth,
    this.laneSeconds,
    this.slipFactor,
  );
  final String label, description;
  final int price;
  final double halfWidth, laneSeconds, slipFactor;

  static Vehicle fromId(String? id) =>
      values.firstWhere((v) => v.name == id, orElse: () => auto);
}
