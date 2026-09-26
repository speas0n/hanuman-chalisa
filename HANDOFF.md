# Current state

The abandoned iOS focus-app idea was replaced by this web app. The user requested memorization support, simple English letters, pronunciation sound, modern styling, and addition to `speas0n/hanuman-chalisa`.

The implementation is static HTML/CSS/JS with 43 passages and 86 bundled synthetic Hindi audio clips. Progress is device-local. Read → hints → recall provides progressive text hiding; self-assessment schedules reviews. No microphone recognition or automatic pronunciation grading is claimed.

Run: `python3 -m http.server 4173 --directory dist`. Test: `npm test`.

Remaining validation: a physical iPhone/Safari run, and fluent human review of Awadhi pronunciation. Synthetic audio is explicitly labelled. The website has no notifications; reviews appear inside it. The iPhone app has optional daily reminders (see below). No offline/PWA caching is implemented.

Future changes should preserve all 43 passages, text/audio alignment, local saved-state compatibility, and accessibility of the mobile Review action. Never bundle personal progress, credentials, model weights, or virtual environments into Git.

## 2026-09-26: iPhone install

The native SwiftUI app (`ios/`) was built, passed all 9 tests (6 unit, 3 UI) on the simulator, and was installed on Season's iPhone 14 through Xcode with a free Personal Team. The developer profile was trusted on the phone, and the app opens there. Free provisioning expires after 7 days; to renew it, reconnect the phone and Run from Xcode again.

## 2026-09-26: reminders and redesign

- Daily reminder (Progress tab): the user picks a time; the default is 7:00 PM. The app schedules 30 one-off notifications, so each can state that day's review count. Today's reminder is skipped once the user has practised. Reminders are rescheduled on launch, on returning to the app, and after every save. Tapping one opens the first passage due for review.
- Streak: practice days are stored under a separate key, `chalisa.days.v1`, so older `chalisa.learning.v1` saves still load.
- Design: navy and saffron hero card with streak and recall counts, serif titles, glowing buttons, a highlight on the line being played, and a celebration with haptics on a successful recall. The Progress tab has a ring, stats, and a tappable map of all 43 passages.
- New files `Reminders.swift` and `Theme.swift` were added to the pbxproj by hand, to keep the signing team (7QAV994F45) that Xcode stored. If you regenerate the project, run `DEVELOPMENT_TEAM=7QAV994F45 python3 ios/generate_project.py`.
- Build for the device with a derived-data path outside Desktop, for example `~/Library/Developer/Xcode/DerivedData/ChalisaDevice`. Inside the Desktop folder, codesign fails with "resource fork … detritus".
- 12 tests pass. The new version was installed on the iPhone and launched. Reminder delivery on the device has not been confirmed yet.
- Fixed 2026-09-26: tapping a reminder crashed the app. The crash log showed a UIKit assertion because the async `didReceive` delegate method finished on a background thread. Now uses the completion-handler forms, which complete on the main thread. `ReminderScheduler.shared` is created with the App, so the delegate is set before a cold-launch tap is delivered. Verified with a temporary UI test (simctl push → tap banner → app in foreground), then reinstalled on the iPhone.
