# Pothole Panic

Little auto. Big city. Bad roads. A complete three-lane arcade game built with
Flutter and Flame for Android, iOS, and the browser.

## Play locally

With Flutter installed:

```powershell
flutter pub get
flutter run -d chrome
```

On this Windows workspace, the SDK and Android tools live in the sibling
`.tooling` directory. The helper handles the SDK's Windows short-path requirement:

```powershell
.\tool\run.ps1 web
.\tool\run.ps1 test
.\tool\run.ps1 check
.\tool\run.ps1 apk
```

To serve the compiled web release:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Then open http://127.0.0.1:8765.
Use HTTP; double-clicking index.html does not work with Flutter web assets.

## Controls and scoring

- Swipe left/right, use A/D or arrow keys, or tap the direction buttons.
- Swipe up, press Space/Up, or tap HORN for a one-second boost with a shield and
  double passenger fare. The cooldown is five seconds from activation.
- Pause with Escape/P or the pause button. App interruptions also pause play.
- Collect green passengers for ₹10 (₹20 while boosting). Avoid potholes.
- Score = displayed distance in metres + collected fare + 5 per near miss.
- One rescue per run: rewarded ad on mobile, clearly labeled free rescue on web.
  A rescue clears nearby hazards and grants 2.5 seconds of protection.

The in-game How to Play screen explains the same rules. High score and sound
preferences persist locally. Quitting from the pause screen banks the run.

## Included

- Original vector rickshaw, road, shops, trees, potholes, people, and app icons.
- Bungee arcade font and its license; original generated WAV effects and ambience.
- Animated scrolling scenery, lane easing/tilt, crash spin/shake, shield effects,
  score popups, main menu, responsive HUD, pause screen, and results screen.
- Distance-based spawning with a continuously reachable safe lane, capped speed,
  deterministic simulation tests, and swept collision detection.
- Adaptive mobile banner, rewarded rescue, interstitial every third finalized run,
  consent handling, privacy choices, and warm-resume app-open ads at the main menu.
- Android, iOS, and web platform projects. No external game backend is required.

Original character voice recordings are not included. Catchphrases appear on
screen; included sounds are original synthesized effects. See ASSETS.md.

## Architecture

`RunModel` owns gameplay state and uses a fixed-step simulation driven by
`PotholeGame`. `SpawnManager` constructs safe rows; `CollisionManager` performs
swept relative-motion collision checks. Flame components render the model;
Flutter widgets render menus and controls. `SaveService` owns local persistence.
`AdManager` owns consent, ad loading, and the fullscreen-ad lock.

Game dimensions are 420 × 800 logical units. The camera scales to the available
viewport. Tune speeds, lane widths, and timing in `game_config.dart` and
`spawn_manager.dart`. The safety floor deliberately overrides the draft's 0.4s
spawn interval: that interval is not fair at boosted top speed.

## Validation

Developed using Flutter 3.47.5 / Dart 3.13.4, Flame 1.38.2, and Mobile Ads 9.1.0.
Commit `pubspec.lock` with the game to reproduce the resolved dependency versions.
The release web and Android APK builds both passed. The APK signature was verified;
it supports Android API 24+ and targets API 36. Native ads still need physical-device
testing. Static analysis is clean and all 12 automated tests pass.

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
flutter build apk --release
```

Tests cover frame-rate-independent scoring, 10,000 safe obstacle rows, boost
expiry, pause behavior, collision tunneling, pickup duplication, single-use rescue,
rapid lane reversal, long-run cleanup, small-screen menus, and full-screen game flow.

## Mobile ads and release configuration

All ad units and both platform application IDs use **Google demo IDs by default**.
Web never initializes the ad SDK. No rewarded-ad completion is faked on mobile.
If an ad cannot load, the player can retry the ad connection or start another run.
Reward is granted only after the earned-reward callback and ad dismissal.

Interstitials appear only when leaving a completed run, after the first two runs,
and are skipped when that run used a rescue. App-open ads are considered only when
returning to the main menu after 30 minutes away; never on a cold start or during play.

Before enabling production ads:

1. Replace the Google sample application ID in AndroidManifest.xml and Info.plist.
2. Configure your AdMob privacy/consent messages, publisher privacy policy, and
   store data disclosures. See PRIVACY.md.
3. Build with `--dart-define=PRODUCTION_ADS=true` and your
   `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`, `ADMOB_REWARDED_ID`,
   and `ADMOB_APP_OPEN_ID` values. Missing production unit IDs disable ads.
4. Configure release signing and your final application/bundle IDs. The included
   Android release configuration uses a local debug signature for sideload testing;
   it is not a store-signed release.
5. Test consent, ad callbacks, offline/recovery behavior, and lifecycle transitions
   on real Android/iOS devices with test ads before submission.

iOS compilation requires macOS and Xcode and cannot be verified on this Windows
host. The source project is included. Configure your Apple signing team and current
Google Mobile Ads iOS requirements before building for distribution.

Useful official references:
- https://docs.flame-engine.org/latest/
- https://developers.google.com/admob/flutter/quick-start
- https://developers.google.com/admob/flutter/rewarded
- https://developers.google.com/admob/flutter/privacy
