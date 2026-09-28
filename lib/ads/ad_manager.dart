import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_units.dart';

class AdManager extends ChangeNotifier {
  static final AdManager instance = AdManager._();
  AdManager._();
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool ready = false,
      showing = false,
      rewardLoading = false,
      _initialized = false;
  bool privacyRequired = false;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  DateTime? _openLoaded, _backgrounded;
  bool get rewardAvailable => _rewarded != null && !showing;

  Future<void> initialize() async {
    if (!supported || _initialized) return;
    _initialized = true;
    rewardLoading = true;
    notifyListeners();
    try {
      if (AdUnits.production &&
          [
            AdUnits.banner,
            AdUnits.interstitial,
            AdUnits.rewarded,
            AdUnits.appOpen,
          ].any((id) => id.isEmpty)) {
        return;
      }
      final consent = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (!consent.isCompleted) consent.complete();
        }),
        (error) {
          if (!consent.isCompleted) consent.complete();
        },
      );
      await consent.future;
      privacyRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (!await ConsentInformation.instance.canRequestAds()) {
        notifyListeners();
        return;
      }
      await MobileAds.instance.initialize();
      ready = true;
      rewardLoading = false;
      notifyListeners();
      loadRewarded();
      _loadInterstitial();
      loadOpenAppAd();
    } catch (error) {
      debugPrint('Ads initialization unavailable: $error');
    } finally {
      // Failed consent/network initialization must be retryable later.
      _initialized = ready;
      if (!ready) rewardLoading = false;
      notifyListeners();
    }
  }

  void retryRewarded() {
    if (ready) {
      loadRewarded();
    } else {
      unawaited(initialize());
    }
  }

  void loadRewarded() {
    if (!ready || rewardLoading || _rewarded != null) return;
    rewardLoading = true;
    notifyListeners();
    RewardedAd.load(
      adUnitId: AdUnits.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          rewardLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          rewardLoading = false;
          notifyListeners();
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (!ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdUnits.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  Future<bool> showRewardedContinue() async {
    final ad = _rewarded;
    if (ad == null || showing) {
      loadRewarded();
      return false;
    }
    _rewarded = null;
    showing = true;
    notifyListeners();
    final done = Completer<bool>();
    bool earned = false;
    void finish(bool result) {
      ad.dispose();
      showing = false;
      _backgrounded = null;
      if (!done.isCompleted) done.complete(result);
      loadRewarded();
      notifyListeners();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(earned),
      onAdFailedToShowFullScreenContent: (_, error) => finish(false),
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          earned = true;
        },
      );
    } catch (_) {
      finish(false);
    }
    return done.future;
  }

  Future<void> showInterstitialIfNeeded(
    int completedRuns, {
    required bool usedReward,
  }) async {
    if (completedRuns < 3 || completedRuns % 3 != 0 || usedReward || showing) {
      return;
    }
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    showing = true;
    final done = Completer<void>();
    void finish() {
      ad.dispose();
      showing = false;
      _backgrounded = null;
      _loadInterstitial();
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    await done.future;
  }

  void loadOpenAppAd() {
    if (!ready || _appOpen != null) return;
    AppOpenAd.load(
      adUnitId: AdUnits.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _openLoaded = DateTime.now();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }

  void background() {
    if (!showing) _backgrounded = DateTime.now();
  }

  void foreground({required bool atMenu}) {
    final since = _backgrounded;
    _backgrounded = null;
    if (!atMenu ||
        showing ||
        since == null ||
        DateTime.now().difference(since) < const Duration(minutes: 30)) {
      return;
    }
    final ad = _appOpen;
    if (ad == null) {
      loadOpenAppAd();
      return;
    }
    _appOpen = null;
    if (_openLoaded == null ||
        DateTime.now().difference(_openLoaded!) >= const Duration(hours: 4)) {
      ad.dispose();
      loadOpenAppAd();
      return;
    }
    showing = true;
    void finish() {
      ad.dispose();
      showing = false;
      _backgrounded = null;
      loadOpenAppAd();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) => finish(),
    );
    ad.show().catchError((Object error) {
      finish();
    });
  }

  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((error) {
      notifyListeners();
    });
  }
}
