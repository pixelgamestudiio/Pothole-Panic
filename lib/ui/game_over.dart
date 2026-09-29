import 'package:flutter/material.dart';
import '../game/components/palette.dart';
import '../game/run_model.dart';
import '../game/game_state.dart';
import '../game/friend_challenge.dart';
import 'friend_challenge_panel.dart';
import 'widgets.dart';

class GameOver extends StatelessWidget {
  const GameOver({
    super.key,
    required this.model,
    required this.best,
    required this.onRetry,
    required this.onHome,
    required this.onContinue,
    required this.canContinue,
    required this.busy,
    required this.browser,
    required this.rewardLoading,
    required this.rewardAvailable,
    required this.onLoadReward,
    this.message,
  });
  final RunModel model;
  final int best;
  final VoidCallback onRetry, onHome, onContinue, onLoadReward;
  final bool canContinue, busy, browser, rewardLoading, rewardAvailable;
  final String? message;
  @override
  Widget build(BuildContext context) => ModalSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Palette.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('ARRE YAAR!', style: arcade(12, color: Palette.ink)),
        ),
        const SizedBox(height: 17),
        Text('END OF THE ROAD', style: arcade(22)),
        const SizedBox(height: 6),
        Text(
          model.lastCrash == ItemKind.barricade
              ? 'Roadworks won this round.'
              : 'That pothole had other plans.',
          style: const TextStyle(color: Color(0xFFB8C6AF), fontSize: 13),
        ),
        const SizedBox(height: 24),
        Text('${model.score}', style: arcade(57, color: Palette.yellow)),
        Text(
          model.score > best ? 'NEW PERSONAL BEST!' : 'TOTAL SCORE',
          style: const TextStyle(
            color: Palette.mint,
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 23),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Palette.cream.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _stat('DISTANCE', '${(model.distance / 10).floor()} m'),
              _stat('FARE', '₹${model.fare}'),
              _stat('COINS', '+${model.coins}'),
            ],
          ),
        ),
        const SizedBox(height: 23),
        if (model.competitive) ...[
          Text(
            model.challengeTarget == 0
                ? 'YOUR CHALLENGE IS READY'
                : model.score > model.challengeTarget
                ? 'YOU BEAT YOUR FRIEND!'
                : model.score == model.challengeTarget
                ? 'IT’S A TIE!'
                : '${model.challengeTarget - model.score} POINTS TO CATCH YOUR FRIEND',
            style: arcade(13, color: Palette.yellow),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (model.challengeTarget > 0)
            Text(
              'Friend: ${model.challengeTarget}  ·  You: ${model.score}',
              style: const TextStyle(color: Palette.mint, fontSize: 12),
            ),
          const SizedBox(height: 12),
          ChallengeShare(
            challenge: FriendChallenge(
              seed: model.courseSeed,
              targetScore: model.score,
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (canContinue) ...[
          GameButton(
            browser
                ? 'ONE MORE CHANCE'
                : rewardAvailable
                ? 'WATCH AD & CONTINUE'
                : rewardLoading
                ? 'LOADING AD…'
                : 'RETRY AD CONNECTION',
            onPressed: busy || rewardLoading
                ? null
                : browser || rewardAvailable
                ? onContinue
                : onLoadReward,
            secondary: true,
            compact: true,
            icon: Icons.favorite_outline,
          ),
          const SizedBox(height: 7),
          Text(
            browser
                ? 'One free rescue per run in the browser edition.'
                : 'Full repair · one rescue per run · 2.5s protection',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF96AE9D), fontSize: 10),
          ),
          const SizedBox(height: 15),
        ],
        if (message != null) ...[
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.orange, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
        GameButton(
          busy
              ? 'PLEASE WAIT…'
              : model.competitive
              ? 'RETRY THIS ROAD'
              : 'ANOTHER ROUND',
          onPressed: busy ? null : onRetry,
          icon: Icons.replay_rounded,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onHome,
          child: const Text(
            'BACK TO THE GARAGE',
            style: TextStyle(
              color: Palette.cream,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _stat(String label, String value) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF96AE9D),
          fontSize: 8,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 7),
      Text(value, style: arcade(16)),
    ],
  );
}
