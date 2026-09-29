import 'package:flutter/material.dart';
import '../game/components/vehicle_art.dart';
import '../game/vehicle.dart';
import '../game/components/palette.dart';

TextStyle arcade(double size, {Color color = Palette.cream}) =>
    TextStyle(fontFamily: 'Bungee', fontSize: size, color: color, height: 1.12);

class GameButton extends StatelessWidget {
  const GameButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary, compact;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: compact ? 48 : 58,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? const Color(0xFF24443B) : Palette.yellow,
        foregroundColor: secondary ? Palette.cream : Palette.ink,
        disabledBackgroundColor: const Color(0xFF385048),
        disabledForegroundColor: const Color(0xFF9BAD9F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: secondary
                ? const Color(0xFF4C6858)
                : const Color(0xFFFFDD6D),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 21),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              style: arcade(
                compact ? 13 : 16,
                color: onPressed == null
                    ? const Color(0xFF9BAD9F)
                    : secondary
                    ? Palette.cream
                    : Palette.ink,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

class RoundControl extends StatelessWidget {
  const RoundControl({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final String label;
  @override
  Widget build(BuildContext context) => IconButton.filled(
    onPressed: onPressed,
    tooltip: label,
    icon: Icon(icon, size: 21),
    style: IconButton.styleFrom(
      minimumSize: const Size(46, 46),
      backgroundColor: Palette.ink.withValues(alpha: 0.9),
      foregroundColor: Palette.cream,
      side: const BorderSide(color: Color(0xFF496052)),
    ),
  );
}

class RickshawIllustration extends StatelessWidget {
  const RickshawIllustration({
    super.key,
    this.size = 130,
    this.vehicle = Vehicle.auto,
  });
  final double size;
  final Vehicle vehicle;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _RickshawPainter(vehicle));
}

class _RickshawPainter extends CustomPainter {
  _RickshawPainter(this.vehicle);
  final Vehicle vehicle;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.16);
    paintVehicle(canvas, vehicle, scale: size.height / 125);
  }

  @override
  bool shouldRepaint(covariant _RickshawPainter oldDelegate) =>
      oldDelegate.vehicle != vehicle;
}

class ModalSurface extends StatelessWidget {
  const ModalSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => BlockSemantics(
    child: ColoredBox(
      color: Palette.ink.withValues(alpha: 0.82),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Palette.ink,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF53634B)),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}
