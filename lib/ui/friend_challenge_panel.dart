import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../game/components/palette.dart';
import '../game/friend_challenge.dart';
import 'widgets.dart';

class FriendChallengePanel extends StatefulWidget {
  const FriendChallengePanel({
    super.key,
    required this.onStart,
    required this.onClose,
    this.lastResult,
    this.initialInvite = '',
  });
  final ValueChanged<FriendChallenge> onStart;
  final VoidCallback onClose;
  final FriendChallenge? lastResult;
  final String initialInvite;
  @override
  State<FriendChallengePanel> createState() => _FriendChallengePanelState();
}

class _FriendChallengePanelState extends State<FriendChallengePanel> {
  late final TextEditingController _input;
  String? _error;
  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialInvite);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _join() {
    try {
      final challenge = FriendChallenge.parse(_input.text);
      widget.onStart(challenge);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => ModalSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('FRIEND CHALLENGE', style: arcade(20, color: Palette.yellow)),
        const SizedBox(height: 12),
        const Text(
          'Take turns on the same road. Beat a friend’s score, then send yours back.',
          style: TextStyle(color: Palette.cream, height: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Auto · 3 health · 16s horn recharge · no rescues\nRoad, rain and lighting match by distance.',
          style: TextStyle(color: Palette.mint, fontSize: 11, height: 1.5),
        ),
        const SizedBox(height: 20),
        GameButton(
          'SET A SCORE',
          onPressed: () => widget.onStart(
            FriendChallenge(seed: Random().nextInt(2147483646), targetScore: 0),
          ),
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _input,
          maxLength: 4096,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Friend’s code or invite',
            counterText: '',
            hintText: 'PP2-…',
            errorText: _error,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _join(),
        ),
        const SizedBox(height: 10),
        GameButton(
          'PLAY FRIEND’S ROAD',
          onPressed: _join,
          secondary: true,
          compact: true,
        ),
        if (widget.lastResult != null) ...[
          const SizedBox(height: 24),
          Text(
            'YOUR LAST CHALLENGE · ${widget.lastResult!.targetScore} POINTS',
            style: const TextStyle(color: Palette.mint, fontSize: 11),
          ),
          const SizedBox(height: 8),
          ChallengeShare(challenge: widget.lastResult!),
        ],
        const SizedBox(height: 12),
        const Text(
          'Casual score challenges. Your friend plays on their own device and shares their result back.',
          style: TextStyle(color: Color(0xFF96AE9D), fontSize: 10, height: 1.5),
        ),
        TextButton(onPressed: widget.onClose, child: const Text('BACK')),
      ],
    ),
  );
}

class ChallengeShare extends StatefulWidget {
  const ChallengeShare({super.key, required this.challenge});
  final FriendChallenge challenge;
  @override
  State<ChallengeShare> createState() => _ChallengeShareState();
}

class _ChallengeShareState extends State<ChallengeShare> {
  String? _message;
  bool _sharing = false;
  String get _invite {
    const configured = String.fromEnvironment('GAME_SHARE_URL');
    final base = FriendChallenge.publicBase(
      configured.isNotEmpty
          ? configured
          : kIsWeb
          ? Uri.base.toString()
          : '',
    );
    return widget.challenge.invite(publicBase: base);
  }

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: _invite));
      if (mounted) {
        setState(
          () => _message =
              'Invite copied. Paste it into a message to your friend.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Copy unavailable. Select and copy the code above.',
        );
      }
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    setState(() => _sharing = true);
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: _invite,
          title: 'Pothole Panic challenge',
          subject: 'Beat my Pothole Panic score',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Sharing is unavailable here. Use Copy Invite instead.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SelectableText(
        widget.challenge.code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Palette.cream,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 10),
      Builder(
        builder: (context) => GameButton(
          'SHARE CHALLENGE',
          onPressed: _sharing ? null : () => _share(context),
          secondary: true,
          compact: true,
          icon: Icons.share_outlined,
        ),
      ),
      TextButton(onPressed: _copy, child: const Text('COPY INVITE')),
      if (_message != null)
        Text(
          _message!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Palette.mint, fontSize: 11),
        ),
    ],
  );
}
