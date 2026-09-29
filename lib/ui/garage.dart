import 'package:flutter/material.dart';
import '../game/components/palette.dart';
import '../game/vehicle.dart';
import '../services/save_service.dart';
import 'widgets.dart';

class Garage extends StatefulWidget {
  const Garage({super.key, required this.save, required this.onClose});
  final SaveService save;
  final VoidCallback onClose;

  @override
  State<Garage> createState() => _GarageState();
}

class _GarageState extends State<Garage> {
  bool _busy = false;
  String? _message;

  Future<void> _choose(Vehicle vehicle) async {
    if (_busy) return;
    setState(() => _busy = true);
    final success = await widget.save.selectOrUnlock(vehicle);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = success
          ? '${vehicle.label} is ready to roll!'
          : 'Could not save. Check storage and try again.';
    });
  }

  @override
  Widget build(BuildContext context) => ModalSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('YOUR GARAGE', style: arcade(25, color: Palette.yellow)),
        const SizedBox(height: 10),
        Text(
          '${widget.save.coins} COINS',
          style: arcade(17, color: Palette.mint),
        ),
        const SizedBox(height: 6),
        const Text(
          'Collect gold coins on the road. Every pickup is worth 5.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 18),
        for (final vehicle in Vehicle.values) _card(vehicle),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.mint, fontSize: 12),
            ),
          ),
        GameButton(
          'BACK TO THE ROAD',
          onPressed: _busy ? null : widget.onClose,
          compact: true,
        ),
      ],
    ),
  );

  Widget _card(Vehicle vehicle) {
    final owned = widget.save.isUnlocked(vehicle);
    final selected = widget.save.selectedVehicle == vehicle;
    final affordable = widget.save.coins >= vehicle.price;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF203C34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Palette.yellow : const Color(0xFF466358),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              RickshawIllustration(size: 62, vehicle: vehicle),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.label, style: arcade(15)),
                    const SizedBox(height: 6),
                    Text(
                      vehicle.description,
                      style: const TextStyle(
                        color: Color(0xFFBDCCB8),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GameButton(
            selected
                ? 'SELECTED'
                : owned
                ? 'SELECT ${vehicle.label}'
                : affordable
                ? 'UNLOCK · ${vehicle.price} COINS'
                : '${vehicle.price - widget.save.coins} MORE COINS NEEDED',
            onPressed: _busy || selected || (!owned && !affordable)
                ? null
                : () => _choose(vehicle),
            secondary: !selected,
            compact: true,
          ),
        ],
      ),
    );
  }
}
