import 'package:flutter/material.dart';
import '../game/components/palette.dart';
import '../game/run_model.dart';
import '../game/road_environment.dart';
import 'widgets.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.model,
    required this.onPause,
    required this.onLeft,
    required this.onRight,
    required this.onHorn,
  });
  final RunModel model;
  final VoidCallback onPause, onLeft, onRight, onHorn;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.ink.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF607359)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'METER RUNNING',
                            style: TextStyle(
                              color: Palette.mint,
                              fontSize: 8,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${model.score}'.padLeft(5, '0'),
                            style: arcade(25),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'FARE',
                            style: TextStyle(
                              color: Palette.mint,
                              fontSize: 8,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '₹${model.fare}',
                            style: arcade(23, color: Palette.yellow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RoundControl(
                icon: Icons.pause_rounded,
                onPressed: onPause,
                label: 'Pause game',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Palette.ink.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: '${model.health} of 3 health',
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < model.health
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: i < model.health
                              ? Palette.orange
                              : const Color(0xFF687A6E),
                          size: 18,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${model.coins} COINS',
                  style: arcade(11, color: Palette.yellow),
                ),
                Text(
                  model.rain > 0.15 ? 'RAIN' : model.daylight.label,
                  style: const TextStyle(
                    color: Palette.mint,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
            decoration: BoxDecoration(
              color: Palette.ink.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${model.difficulty.label} · ${model.meters.floor()} m',
                      style: arcade(10, color: Palette.yellow),
                    ),
                    Text(
                      model.difficulty == Difficulty.hard
                          ? 'ENDLESS'
                          : model.difficulty == Difficulty.easy
                          ? 'MEDIUM AT 500 m'
                          : 'HARD AT 1,000 m',
                      style: const TextStyle(color: Palette.mint, fontSize: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: model.stageProgress.clamp(0, 1),
                  minHeight: 3,
                  color: Palette.yellow,
                  backgroundColor: const Color(0xFF35544A),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Palette.ink.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              model.shielded
                  ? 'SHIELD ON  ·  KEEP GOING!'
                  : model.skidLeft > 0
                  ? 'OIL SKID · KEEP STEERING'
                  : model.competitive
                  ? model.challengeTarget == 0
                        ? 'FRIEND CHALLENGE · SET YOUR SCORE'
                        : model.score > model.challengeTarget
                        ? 'TARGET BEATEN · KEEP GOING!'
                        : 'FRIEND’S SCORE: ${model.challengeTarget} · KEEP GOING!'
                  : '${model.district} · ${model.conditions}',
              style: const TextStyle(
                color: Palette.cream,
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Spacer(),
        if (model.stageBannerLeft > 0)
          IgnorePointer(
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Palette.ink.withValues(alpha: .94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Palette.yellow),
              ),
              child: Text(
                '${model.difficulty.label} · KEEP ROLLING!',
                style: arcade(15, color: Palette.yellow),
              ),
            ),
          ),
        if (model.elapsed < 6)
          IgnorePointer(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.ink.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SWIPE TO DODGE. SWIPE UP TO HONK.',
                style: TextStyle(
                  color: Palette.cream,
                  fontSize: 10,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          child: Row(
            children: [
              _steer(Icons.arrow_back_rounded, onLeft, 'Move left'),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 61,
                  child: FilledButton(
                    onPressed: model.cooldown > 0 ? null : onHorn,
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.yellow,
                      foregroundColor: Palette.ink,
                      disabledBackgroundColor: Palette.ink.withValues(
                        alpha: 0.92,
                      ),
                      disabledForegroundColor: Palette.cream,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF748063)),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.campaign_rounded, size: 21),
                            const SizedBox(width: 6),
                            Text(
                              model.cooldown > 0
                                  ? '${model.cooldown.ceil()}s'
                                  : 'HORN!',
                              style: arcade(
                                17,
                                color: model.cooldown > 0
                                    ? Palette.cream
                                    : Palette.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          model.cooldown > 0
                              ? 'RECHARGING'
                              : 'SHIELD + 2× FARE',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _steer(Icons.arrow_forward_rounded, onRight, 'Move right'),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _steer(IconData icon, VoidCallback action, String label) => Semantics(
    label: label,
    button: true,
    child: SizedBox(
      width: 62,
      height: 61,
      child: IconButton.filled(
        onPressed: action,
        tooltip: label,
        icon: Icon(icon, size: 27),
        style: IconButton.styleFrom(
          backgroundColor: Palette.ink.withValues(alpha: 0.93),
          foregroundColor: Palette.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Color(0xFF748063)),
        ),
      ),
    ),
  );
}
