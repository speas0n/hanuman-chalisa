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

## 2026-09-27: Home Screen and Lock Screen widget

- New `ChalisaWidget` app extension, bundle id `com.season.chalisa.widget`, embedded in the app. It is a "Verse of the Day" widget in small, medium and large sizes, plus Lock Screen rectangular, circular and inline versions.
- `DailyPassage.id(on:)` picks one passage per day, in order, starting from 2026-01-01. The widget's timeline holds a week of midnight entries.
- Tapping the widget opens `chalisa://passage/<id>`. The app registers that scheme (`Chalisa/Info.plist`, merged with the generated plist) and selects the passage in `RootView.onOpenURL`.
- The app and the widget share `Models.swift`, `Palette.swift` (colors, moved out of `Theme.swift`) and `DailyPassage.swift`. The widget also bundles `verses.json` and `Assets.xcassets`.
- There is no App Group on purpose: free Personal Teams cannot sign one. As a result, the widget cannot show the streak or due reviews. Showing them would need a paid account, an App Group, and the store saving to shared `UserDefaults`.
- The project was regenerated with `DEVELOPMENT_TEAM=7QAV994F45 python3 ios/generate_project.py`. The generator now builds the extension, the embed phase, and the shared sources.
- All 14 tests pass: 11 unit tests, including 2 new ones for the day rotation and the link, and 3 UI tests. The widget layouts were checked by rendering them to images on the simulator. 
- Widget art: `HanumanLeap` imageset (Season's leaping Hanuman). It is a transparent cutout, trimmed and scaled to 744×1080; the source alpha topped out at 254 and was set to 255. The app's hero card still uses `Hanuman`.
- 2026-09-28: installed on Season's iPhone 14 ("Speason") over Wi-Fi, with no cable. Build with `xcodebuild … -destination 'id=00008110-000E35990C79401E' -derivedDataPath ~/Library/Developer/Xcode/DerivedData/ChalisaDevice -allowProvisioningUpdates build`, then install with `xcrun devicectl device install app --device 00008110-000E35990C79401E <path to Chalisa.app>`. The phone must be on the same Wi-Fi and unlocked. The free provisioning from this install lasts until about 2026-10-05. How the widget looks on the phone has not been confirmed yet.
- The widget changes were committed and pushed on 2026-09-30, together with the Read tab.


## 2026-09-30: Read tab

- New `Read` tab, second in the tab bar (between Practice and Library). `ReadView.swift` lists all 43 passages in order under "Opening dohas", "Chalisa" and "Closing doha" (same grouping as Library), in serif type that scales with Dynamic Type. Each passage is one accessibility element with the identifier `read<id>`. Long-pressing a passage offers "Practise this passage", which selects it and switches to Practice.
- A "Listen" card at the top links out to "Hanuman Chalisa (Lofi)" by Rasraj Ji Maharaj in YouTube Music (`https://music.youtube.com/watch?v=MeCHQb9nKhg`). It is a plain `Link`. The audio is copyrighted, so it is never downloaded, bundled or streamed in the app.
- `ChalisaApp.swift` gained `AppTab.read` and the tab. The project was regenerated with `DEVELOPMENT_TEAM=7QAV994F45 python3 generate_project.py` (run from `ios/`). The generator globs `Chalisa/*.swift`, so `ReadView.swift` joined the app target only; the widget still builds just its own files plus the three shared ones. The diff against the previous project is only the new file, and the signing team is unchanged.
- New UI test `testReadPageShowsEveryPassage` (taps Read, finds `read2`, scrolls to `read42`). 15 tests pass: 11 unit, 4 UI. Screenshots are in `.impeccable/review/read-light.png` and `read-dark.png`.
- Installed on the iPhone 14 over Wi-Fi on 2026-09-30, with the same `xcodebuild` and `devicectl` commands as above, and launched. The Listen link and the "Practise this passage" menu have not yet been tried on the phone. Free provisioning ends around 2026-10-05, or a few days later if this build renewed the profile.
- Committed and pushed to `speas0n/hanuman-chalisa` on 2026-09-30, together with the widget work.
