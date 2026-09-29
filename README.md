# Pothole Panic

Your ride. Big city. Bad roads. A three-lane arcade game built with
Flutter and Flame for Android, iOS, and the browser.

## Road, Garage & Friends update — 1.2.0

- Garage: starter auto, city car (100 coins), motorbike (150 coins). The car has
  stronger grip and a wider collision body; the bike steers faster but wobbles more on oil.
- Gold pickups award 5 coins and save immediately. Purchases and the selected
  vehicle persist locally. Coins are separate from score and passenger fares.
- Three health points per run. Potholes and barricades cost one point, with a
  1.25-second grace period after damage. A rescue restores all three points.
- Oil disrupts balance and grip for one second, with body lean and tire marks.
  Counter-steering remains possible; a ready horn clears the skid. Mud is removed.
- Dry roads transition to rain after 25 seconds, reaching full rain at 30 seconds.
  Rain reduces grip and speed, then clears from 55 to 70 seconds; the cycle repeats.
- Easy runs from 0–499 m, Medium from 500–999 m, and Hard from 1,000 m.
  Base speed rises from 340 to 540 logical units/s at 1,000 m, capping at 740.
  Controlled variation mixes singles, gates, staggered hazards, lane holds and
  slaloms. Gaps vary within each sequence, with occasional recovery stretches.
  Wider crossings unlock at 3,000 m, four-beat combinations at 6,000 m, and
  tighter combinations at 10,000 m. Staying in a lane can be the right choice.
  Clearance reserves 0.38s for a hold, 0.72s for a lane change and 1.14s for a
  two-lane crossing at boosted speed, plus staggered-tail clearance.
  Rewards are intermittent and can offer reachable detours rather than always
  pointing out the designated safe route.
- Lighting changes automatically: day to afternoon at 500 m, night at 1,000 m,
  dawn at 2,000 m, then repeats. Each transition blends over the preceding 100 m.
  Night adds headlights and roadside lamps while keeping hazards readable.
- Residential, bazaar, open-road, and roadworks districts change every 800 m.
  Varied building spacing, gardens, stalls, and construction details reduce repetition.
- Rain includes varied droplets, impact ripples, wet-road reflections, tire spray,
  and original rain audio. The top-down camera is retained.

Existing high scores, sound settings and run statistics are preserved. Garage
progress is stored only on this device/browser; clearing app data resets it.
Jeep, bicycle, animals, deliveries and curved roads are reserved for later updates.

## Friend challenges

Open **Friend Challenge → Set a Score**, finish a run, then choose **Share
Challenge** or **Copy Invite**. Your friend opens Friend Challenge, pastes the
code or entire invite, and chooses **Play Friend’s Road**. They can share their
result back. The last completed challenge remains available from the menu.

Both players use the auto, three health points, a 16-second horn recharge and
no rescue continues. A versioned seed reproduces obstacle positions regardless
of frame rate or horn use. Challenge rain and lighting follow distance, so the
same road sections have the same conditions. Retry keeps the same seed/target;
starting a normal run restores the selected garage vehicle and normal rules.

This is asynchronous, casual multiplayer: no accounts, live opponents, server
leaderboard or verified anti-cheat. The invite checksum catches copying errors;
it does not authenticate a score. Players need the same game/rules version.

Codes work between devices running this version. On a public HTTPS web deployment,
invites also include a link that pre-fills the challenge panel. Mobile builds can
add that link with `--dart-define=GAME_SHARE_URL=https://your-game-domain/`.
Localhost previews deliberately share codes without an unusable localhost link.
Native share sheets still need device testing after APK rebuild approval.

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
.\tool\run.ps1 build-web
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Then open http://127.0.0.1:8765.
Use HTTP; double-clicking index.html does not work with Flutter web assets.
The build helper adds content hashes to JavaScript entrypoint URLs so a refresh
loads the latest game instead of a previously cached menu.

## Controls and scoring

- Swipe left/right, use A/D or arrow keys, or tap the direction buttons.
- Swipe up, press Space/Up, or tap HORN for a one-second boost with a shield and
  double passenger fare. Speed increases by 35%; the cooldown is 16 seconds of
  active gameplay from activation. Pausing freezes it; a rescue does not reset it.
- Pause with Escape/P or the pause button. App interruptions also pause play.
- Collect green passengers for ₹10 (₹20 while boosting), and gold coins for unlocks.
- Score = displayed distance in metres + collected fare + 5 per near miss.
- One rescue per run: rewarded ad on mobile, clearly labeled free rescue on web.
  A rescue restores health, clears nearby hazards and grants 2.5 seconds of protection.

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
Android supports API 24+ (Android 7.0+) and targets API 36. Version 1.2.1 fixes
an Android release startup crash in WorkManager's Room database: R8 full mode
removed a constructor instantiated through reflection. The app's ProGuard rules
now explicitly preserve Room database constructors while keeping optimization.
The fix was verified on an Android 16 emulator with three cold launches and
visible gameplay. This does not certify every Android version or phone model.
Versions 1.0.0 and 1.2.0 both reproduced the startup crash; use the 1.2.1 APK.
Native ads and device performance still need physical-device testing.
Run the commands below to validate changes without rebuilding Android.

```powershell
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

Tests cover frame-rate-independent scoring, 12,000 varied obstacle sequences, boost
expiry, pause behavior, collision tunneling, pickup duplication, single-use rescue,
rapid lane reversal, long-run cleanup, small-screen menus, and full-screen game flow.
Environment tests cover difficulty boundaries, continuous speed, automatic lighting,
safe corridors at each difficulty, and all nine vehicle/lighting combinations.
Friend tests cover code validation, copy/join/retry flow, saved invites and
matching courses under different frame rates and horn use. `tool/verify_course.dart`
can run on Dart VM and compiled JavaScript to compare course fingerprints.
Run `.\tool\run.ps1 dry-run` to capture those combinations in `outputs/`.

For manual retesting, drive past 1,000 m to check uneven gaps, lane holds and
staggered hazards. Check one-second oil wobble and the 16-second horn recharge.
Play past 25 seconds for rain in normal runs, and pause/resume to check audio.
Watch daylight return at 2,000 m. Create a friend challenge, finish, copy its
invite, and paste it into Friend Challenge on another browser/device running
this version. Confirm the target score, same course, retry and saved last invite.
After every Android release build, run the emulator startup check before sharing:

```powershell
.\tool\smoke-apk.ps1 -ApkPath build\app\outputs\flutter-apk\app-release.apk -AdbPath <path-to-adb.exe>
```

The check installs onto `emulator-5554` (override with `-Serial`), tests three cold
launches and checks for crashes and a foreground game activity. It intentionally
refuses physical-device serials. Verify gameplay, audio, sharing and lifecycle
behavior separately on real devices. APK signature and build checks alone cannot
detect native runtime startup failures. Keep versioned APK filenames to avoid
confusing old downloads with the current build.

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
