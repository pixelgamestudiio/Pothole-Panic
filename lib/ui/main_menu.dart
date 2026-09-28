import 'package:flutter/material.dart';
import '../game/components/palette.dart';
import 'widgets.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({
    super.key,
    required this.best,
    required this.onStart,
    required this.onHelp,
    required this.onSound,
    required this.sound,
  });
  final int best;
  final VoidCallback onStart, onHelp, onSound;
  final bool sound;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF102D29), Color(0xF2102D29), Color(0xDD102D29)],
      ),
    ),
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Palette.mint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LOOP GAMES  /  NO. 001',
                                style: TextStyle(
                                  color: Palette.mint,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      RoundControl(
                        icon: sound
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        onPressed: onSound,
                        label: sound ? 'Mute sound' : 'Enable sound',
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF6C7750)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'THREE LANES. ZERO ROAD SENSE.',
                          style: TextStyle(
                            color: Palette.cream,
                            fontSize: 10,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 19),
                      FittedBox(child: Text('POTHOLE', style: arcade(53))),
                      FittedBox(
                        child: Text(
                          'PANIC!',
                          style: arcade(73, color: Palette.yellow),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Little auto. Big city. Bad roads.',
                        style: TextStyle(
                          color: Color(0xFFB8C6AF),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 170,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: -0.16,
                              child: Container(
                                width: 143,
                                height: 143,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Palette.yellow.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Palette.yellow.withValues(
                                      alpha: 0.17,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const RickshawIllustration(size: 130),
                            Positioned(
                              right: 12,
                              top: 30,
                              child: Transform.rotate(
                                angle: 0.1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Palette.orange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'HORN OK\nPLEASE',
                                    style: arcade(10, color: Palette.ink),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            color: Palette.yellow,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PERSONAL BEST  ',
                            style: TextStyle(
                              color: Palette.cream.withValues(alpha: 0.65),
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '$best',
                            style: arcade(20, color: Palette.yellow),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                  Column(
                    children: [
                      GameButton(
                        'CHALO! LET’S RIDE',
                        onPressed: onStart,
                        icon: Icons.arrow_forward_rounded,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: onHelp,
                        child: const Text(
                          'FIRST TIME?  HOW TO PLAY',
                          style: TextStyle(
                            color: Palette.cream,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'DODGE POTHOLES  •  PICK UP PEOPLE  •  KEEP ROLLING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF809D87),
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
