import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ads/ad_manager.dart';
import 'ads/banner_slot.dart';
import 'game/components/palette.dart';
import 'game/game_state.dart';
import 'game/managers/audio_manager.dart';
import 'game/pothole_game.dart';
import 'services/save_service.dart';
import 'ui/game_hud.dart';
import 'ui/game_over.dart';
import 'ui/main_menu.dart';
import 'ui/pause_menu.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(PotholePanicApp(save: SaveService(prefs)));
}

class PotholePanicApp extends StatelessWidget {
  const PotholePanicApp({super.key, required this.save});
  final SaveService save;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pothole Panic',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Palette.yellow,
        brightness: Brightness.dark,
        surface: Palette.ink,
      ),
      scaffoldBackgroundColor: const Color(0xFF091D1B),
    ),
    home: GameScreen(save: save),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.save, this.audioOverride});
  final SaveService save;
  final AudioManager? audioOverride;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final AudioManager audio;
  late final PotholeGame game;
  final ads = AdManager.instance;
  final focus = FocusNode(debugLabel: 'game controls');
  Offset? _gestureStart;
  bool _swiped = false, _busy = false, _banked = false, _help = false;
  String? _message;
  int _previousBest = 0;
  bool get sound => audio.enabled;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = widget.audioOverride ?? AudioManager(enabled: widget.save.sound);
    game = PotholeGame(
      audio: audio,
      onRunEnded: () {
        unawaited(widget.save.saveBest(game.model.score));
        if (AdManager.supported) ads.loadRewarded();
      },
    );
    ads.addListener(_adsChanged);
    unawaited(
      ads.initialize().catchError((Object error) {
        debugPrint('Ads unavailable: $error');
      }),
    );
  }

  void _adsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ads.foreground(atMenu: game.model.phase == GamePhase.menu && !_help);
    } else {
      game.pauseRun();
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        ads.background();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ads.removeListener(_adsChanged);
    focus.dispose();
    unawaited(audio.dispose());
    super.dispose();
  }

  void _start() {
    _previousBest = widget.save.best;
    _banked = false;
    _message = null;
    game.startRun();
    focus.requestFocus();
  }

  Future<void> _sound() async {
    await audio.toggle(!sound);
    await widget.save.setSound(sound);
    if (mounted) setState(() {});
  }

  Future<void> _finish({required bool restart}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!_banked) {
        _banked = true;
        await widget.save.record(game.model.score, game.model.fare);
        await ads.showInterstitialIfNeeded(
          widget.save.runs,
          usedReward: game.model.continued,
        );
      }
      if (!mounted) return;
      if (restart) {
        _start();
      } else {
        game.menu();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    if (_busy || game.model.continued) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final earned = !AdManager.supported || await ads.showRewardedContinue();
    if (!mounted) return;
    if (earned) {
      game.model.revive();
      game.refresh();
      focus.requestFocus();
    } else {
      _message = 'Rescue not earned. Try again or start a new run.';
    }
    setState(() => _busy = false);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _busy || _help) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      game.steer(-1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      game.steer(1);
    } else if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.space) {
      game.horn();
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyP) {
      if (game.model.phase == GamePhase.playing) {
        game.pauseRun();
      } else if (game.model.phase == GamePhase.paused) {
        game.resumeRun();
      }
    } else if (key == LogicalKeyboardKey.enter &&
        game.model.phase == GamePhase.menu) {
      _start();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _swipe(PointerMoveEvent event) {
    if (_gestureStart == null || _swiped || _help) return;
    final delta = event.localPosition - _gestureStart!;
    if (delta.distance < 24) return;
    if (delta.dx.abs() > delta.dy.abs()) {
      game.steer(delta.dx.sign.toInt());
    } else if (delta.dy < 0) {
      game.horn();
    }
    _swiped = true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Focus(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: _key,
      child: LayoutBuilder(
        builder: (context, available) => Stack(
          children: [
            if (available.maxWidth > 850)
              Positioned(
                left: 44,
                bottom: 36,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A LITTLE CHAOS.\nA LOT OF CHALO.',
                      style: arcade(20, color: const Color(0xFF3C5C4D)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '← →  /  A D     CHANGE LANES\n↑  /  SPACE    HORN BOOST\nESC  /  P       CHAI BREAK',
                      style: TextStyle(
                        color: Color(0xFF668371),
                        fontSize: 10,
                        height: 2,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 420 / 800,
                        child: ClipRect(
                          child: ValueListenableBuilder<int>(
                            valueListenable: game.revision,
                            builder: (context, revision, child) {
                              final phase = game.model.phase;
                              return PopScope(
                                canPop: phase == GamePhase.menu,
                                onPopInvokedWithResult: (didPop, result) {
                                  if (!didPop && phase == GamePhase.playing) {
                                    game.pauseRun();
                                  }
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Listener(
                                      onPointerDown: (e) {
                                        _gestureStart = e.localPosition;
                                        _swiped = false;
                                        focus.requestFocus();
                                      },
                                      onPointerMove: _swipe,
                                      onPointerUp: (_) {
                                        _gestureStart = null;
                                      },
                                      onPointerCancel: (_) {
                                        _gestureStart = null;
                                      },
                                      child: GameWidget(
                                        game: game,
                                        loadingBuilder: (_) => const Center(
                                          child: CircularProgressIndicator(
                                            color: Palette.yellow,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (phase == GamePhase.menu)
                                      MainMenu(
                                        best: widget.save.best,
                                        onStart: _start,
                                        onHelp: () =>
                                            setState(() => _help = true),
                                        onSound: _sound,
                                        sound: sound,
                                      ),
                                    if (phase == GamePhase.playing ||
                                        phase == GamePhase.dying)
                                      GameHud(
                                        model: game.model,
                                        onPause: game.pauseRun,
                                        onLeft: () => game.steer(-1),
                                        onRight: () => game.steer(1),
                                        onHorn: game.horn,
                                      ),
                                    if (phase == GamePhase.paused)
                                      PauseMenu(
                                        onResume: game.resumeRun,
                                        onQuit: () => _finish(restart: false),
                                        onSound: _sound,
                                        sound: sound,
                                      ),
                                    if (phase == GamePhase.gameOver)
                                      GameOver(
                                        model: game.model,
                                        best: _previousBest,
                                        onRetry: () => _finish(restart: true),
                                        onHome: () => _finish(restart: false),
                                        onContinue: _continue,
                                        canContinue: !game.model.continued,
                                        busy: _busy,
                                        browser: !AdManager.supported,
                                        rewardLoading: ads.rewardLoading,
                                        rewardAvailable: ads.rewardAvailable,
                                        onLoadReward: ads.retryRewarded,
                                        message: _message,
                                      ),
                                    if (_help) _helpPanel(),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (AdManager.supported && ads.ready)
                      const SafeArea(top: false, child: BannerSlot()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _helpPanel() => ModalSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('ROAD RULES', style: arcade(26, color: Palette.yellow)),
        const SizedBox(height: 23),
        _tip(
          Icons.swipe_rounded,
          'DODGE',
          'Swipe left or right. Arrow keys and A / D work too.',
        ),
        _tip(
          Icons.person_pin_circle_outlined,
          'PICK UP',
          'Green passengers earn ₹10. Every fare adds to your score.',
        ),
        _tip(
          Icons.campaign_rounded,
          'HONK',
          'Swipe up or press Space: 1 second of speed, a shield, and double fare. Recharges in 5 seconds.',
        ),
        _tip(
          Icons.favorite_outline,
          'KEEP GOING',
          'One rescue per run. Near misses earn 5 bonus points.',
        ),
        const SizedBox(height: 8),
        GameButton('GOT IT!', onPressed: () => setState(() => _help = false)),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Privacy & credits'),
              content: SingleChildScrollView(
                child: Text(
                  AdManager.supported
                      ? 'Scores and sound preferences are saved on this device. This build uses Google test ads. The Google Mobile Ads SDK may process device and advertising data. Consent controls are shown where required. No game account or location permission is requested.\n\nOriginal vector art and synthesized sound effects. Bungee typeface by David Jonathan Ross, SIL Open Font License. Built with Flutter and Flame.'
                      : 'Scores and sound preferences are saved in this browser. This edition has no ads or analytics. No game account or location permission is requested.\n\nOriginal vector art and synthesized sound effects. Bungee typeface by David Jonathan Ross, SIL Open Font License. Built with Flutter and Flame.',
                ),
              ),
              actions: [
                if (ads.privacyRequired)
                  TextButton(
                    onPressed: ads.showPrivacyOptions,
                    child: const Text('Ad privacy choices'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
          ),
          child: const Text(
            'PRIVACY & CREDITS',
            style: TextStyle(color: Palette.mint, fontSize: 10),
          ),
        ),
      ],
    ),
  );
  Widget _tip(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Palette.mint, size: 27),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: arcade(13)),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFB8C6AF),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
