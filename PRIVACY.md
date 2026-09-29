# Privacy notes for the development build

Pothole Panic saves the best score, completed-run count, total collected fare,
sound preference, coin balance, unlocked vehicles, selected vehicle and the
last completed friend-challenge code locally
with shared_preferences. It has no accounts,
server leaderboard, developer analytics, contacts access, or location request.

Friend invites contain a road seed, rules version and target score. Share uses
the device share sheet; Copy Invite places the text on the clipboard. The player
chooses the destination. There is no contacts access or automatic result upload.
On a public web deployment, an invite link includes the code in its URL; the
hosting service may log URLs according to its own configuration.

The web edition does not initialize advertising SDKs or show ads. Its one rescue
per normal run is free; friend challenges have no rescue. Browser storage can be
removed with the browser's site-data controls.

Android and iOS include Google's Mobile Ads and User Messaging Platform SDKs.
Google test ad IDs are the default. Those SDKs can process advertising identifiers,
device and network information, diagnostics, and ad interactions under Google's
policies. Ads are requested only after the consent SDK says requests are allowed.
When the SDK requires it, ad privacy choices appear in How to Play → Privacy & Credits.

Before a public mobile release, the publisher must supply its identity, contact
information, a hosted privacy-policy URL, region-appropriate consent messages,
and accurate Play/App Store data disclosures reflecting its final SDK configuration.
This development note is not a finalized publisher privacy policy.

References:
- https://developers.google.com/admob/flutter/privacy
- https://developers.google.com/admob/android/privacy/play-data-disclosure
- https://policies.google.com/privacy
