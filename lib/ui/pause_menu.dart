import 'package:flutter/material.dart';
import '../game/components/palette.dart';
import 'widgets.dart';

class PauseMenu extends StatelessWidget {
  const PauseMenu({
    super.key,
    required this.onResume,
    required this.onQuit,
    required this.onSound,
    required this.sound,
  });
  final VoidCallback onResume, onQuit, onSound;
  final bool sound;
  @override
  Widget build(BuildContext context) => ModalSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_cafe_outlined, size: 38, color: Palette.yellow),
        const SizedBox(height: 18),
        Text('CHAI BREAK', style: arcade(27)),
        const SizedBox(height: 10),
        const Text(
          'The traffic can wait.',
          style: TextStyle(color: Palette.mint),
        ),
        const SizedBox(height: 26),
        GameButton(
          'BACK TO THE ROAD',
          onPressed: onResume,
          icon: Icons.play_arrow_rounded,
        ),
        const SizedBox(height: 12),
        GameButton(
          sound ? 'SOUND ON' : 'SOUND OFF',
          onPressed: onSound,
          secondary: true,
          compact: true,
          icon: sound ? Icons.volume_up : Icons.volume_off,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onQuit,
          child: const Text(
            'END RUN & GO HOME',
            style: TextStyle(color: Palette.cream),
          ),
        ),
      ],
    ),
  );
}
