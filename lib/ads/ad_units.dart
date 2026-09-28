import 'package:flutter/foundation.dart';

/// Google demo units. Production builds require explicit --dart-define values.
abstract final class AdUnits {
  static const production = bool.fromEnvironment('PRODUCTION_ADS');
  static bool get ios => defaultTargetPlatform == TargetPlatform.iOS;
  static String get banner => production
      ? const String.fromEnvironment('ADMOB_BANNER_ID')
      : ios
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';
  static String get interstitial => production
      ? const String.fromEnvironment('ADMOB_INTERSTITIAL_ID')
      : ios
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';
  static String get rewarded => production
      ? const String.fromEnvironment('ADMOB_REWARDED_ID')
      : ios
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';
  static String get appOpen => production
      ? const String.fromEnvironment('ADMOB_APP_OPEN_ID')
      : ios
      ? 'ca-app-pub-3940256099942544/5575463023'
      : 'ca-app-pub-3940256099942544/9257395921';
}
