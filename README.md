# Hanuman Chalisa practice

A native iPhone app and a mobile-friendly website to help you remember the Hanuman Chalisa, one passage at a time.

## iPhone app

Open `ios/Chalisa.xcodeproj` in Xcode. Choose the **Chalisa** scheme and an iPhone simulator, then Run. Requires iOS 17 or later; no third-party Swift packages are needed.

The SwiftUI app uses native Practice, Library, and Progress tabs, system controls, light/dark appearance, Dynamic Type, and VoiceOver labels. All text and 86 pronunciation clips are bundled, so practice works offline. Saved progress stays on the phone and is separate from the website. Audio stops when the app leaves the foreground.

- **Daily reminder:** turn it on in the Progress tab and choose a time (default 7:00 PM). Each reminder says how many passages are ready to review that day, or which verse to continue. It skips the day once you have practised. Tapping it opens the first passage due for review. The app schedules the next 30 days and refreshes them whenever it opens.
- **Streak and progress:** the Practice screen shows your day streak and recall count. The Progress tab has a ring, stats, and a map of all 43 passages. Brighter tiles have been remembered longer, and outlined tiles are due; tap one to practise it.
- **Design:** navy-and-saffron artwork card, serif titles, a highlight on the line being played, and a celebration with haptics when you remember a passage. Works in light and dark mode.

To install on your own iPhone:

1. In Xcode → Settings → Accounts, sign in with a **free Apple Account**.
2. Connect and unlock the iPhone. Accept its “Trust This Computer” prompt if shown.
3. In the Chalisa target's Signing & Capabilities, select your **Personal Team**. Keep automatic signing enabled. If the bundle identifier is unavailable, use a unique identifier for your own copy.
4. Select your iPhone as the run destination. Enable **Developer Mode** on the phone if Xcode requests it, then Run. If iOS asks you to trust the developer, follow Settings → General → VPN & Device Management.

A paid Apple Developer Program membership is unnecessary for personal testing. Free provisioning expires after seven days; reconnect and run from Xcode to refresh it. If this folder is inside Desktop or Documents with iCloud sync, a command-line signed build can fail with “resource fork, Finder information, or similar detritus not allowed”. Build into `~/Library/Developer/Xcode/DerivedData` instead (Xcode's Run button already does). Installing with no Apple Account is not supported by this workflow. See [Apple's account guidance](https://developer.apple.com/help/account/basics/about-your-developer-account).

Simulator tests and an unsigned device build can be run with:

```sh
xcodebuild -project ios/Chalisa.xcodeproj -scheme Chalisa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ios/build test CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO -collect-test-diagnostics never
xcodebuild -project ios/Chalisa.xcodeproj -scheme Chalisa \
  -destination 'generic/platform=iOS' -configuration Release \
  -derivedDataPath ios/build-device build CODE_SIGNING_ALLOWED=NO
```

The shared scheme runs tests without attaching a debugger. Choose an installed simulator name on other Macs. Unit tests cover offline clips, scheduling, repeated recalls, daylight-saving boundaries, saved-state validation, persistence, and reset. Unit tests also cover streaks and the daily reminder plan. UI tests cover playback, hints, recall, Library search, Settings, and restarting the app. An unsigned build verifies compilation; it cannot be installed until Xcode signs it for your phone.

The Xcode project is checked in. `python3 ios/generate_project.py` regenerates it if Swift files are added or targets change. Set `DEVELOPMENT_TEAM` in the environment to keep your signing team, or select it again in Xcode afterwards. Audio is referenced directly from `dist/audio`; keep that folder alongside `ios`. Roman text is bundled in `ios/Chalisa/Resources/verses.json` and must stay aligned with `dist/verses.js`.

## Use it

1. **Read:** listen to each line and repeat it aloud.
2. **Hints:** alternate words disappear. Tap a hidden word for help.
3. **Recall:** try both lines without the text, reveal the answer, then rate yourself.

Includes all 40 verses, two opening dohas, and the closing doha. Text uses simple English letters. Every line has a bundled pronunciation clip, with slower playback and three-repeat practice. Progress is saved locally in your browser; it does not sync between devices. Successful recalls schedule review in 1, 3, 7, then 14 days. Difficult passages remain due today. Repeating a success on the same day does not increase its review stage.

## Run the website locally

Requires Python 3. No application packages or build step.

```sh
python3 -m http.server 4173 --directory dist
```

Open http://localhost:4173. Serve the `dist` directory on any static HTTPS host to use it on your phone. On iPhone, open the hosted URL in Safari and use Share → Add to Home Screen if desired. The website needs a connection for audio; offline caching is not implemented there. The native iPhone app bundles its audio for offline use.

## Tests

Node.js 18 or later:

```sh
npm test
```

Tests cover passage structure, bundled audio presence, scheduling, repeated daily recalls, date boundaries, and corrupt stored state. Browser checks cover read/hints/recall, answer reveal, progress persistence, audio playback, navigation and mobile overflow. Physical iPhone/Safari playback has not yet been verified.

## Content and audio

- Traditional public-domain text: Hanuman Chalisa by Tulsidas. [Reference text](https://www.indiapress.org/salasar/Chalisa.pdf). Roman spellings were simplified and prepared for this app; spelling and recitation conventions vary.
- Audio: generated locally with [Kokoro-82M v1.0](https://huggingface.co/hexgrad/Kokoro-82M), `hm_omega`, Hindi `hi`, speed `0.85`, through `kokoro-onnx` 0.6.1. Kokoro model weights are Apache-2.0. This is synthetic spoken guidance, not a sung or authoritative recitation. A fluent reciter should review pronunciation before using it as a teaching standard.
- `dist/audio/manifest.json` records the source text, generator, and duration of each of the 86 clips. No Apple system-voice clips are included in the final repository.
- Hanuman illustration: AI-generated original artwork for this app.
- DM Sans and Lora: self-hosted fonts under the SIL Open Font License, with license copies in `dist/fonts`.
- No login, analytics, microphone access, API keys, or application backend. Clear browser storage to remove local progress, or use About → Reset my progress.

## Regenerate the audio

This is optional; the MP3s are already included. Install Python dependencies into a virtual environment:

```sh
python3 -m venv .audio-venv
.audio-venv/bin/pip install kokoro-onnx==0.6.1 soundfile
mkdir -p .models
curl -L -o .models/kokoro-v1.0.onnx https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx
curl -L -o .models/voices-v1.0.bin https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin
.audio-venv/bin/python generate_audio.py
```

Also requires Node.js and FFmpeg. Model files and environments are ignored by Git. Audio generation overwrites clips, so review the result before committing.

## Files

- `dist/index.html`, `style.css`, `app.js`: interface and practice flow.
- `dist/verses.js`: full text and matching Devanagari audio input.
- `dist/progress.js`: review scheduling and saved-state validation.
- `dist/audio/`: pronunciation clips and generation manifest.
- `tests/`: dependency-free tests.
- `.openai/hosting.json`: private Sites hosting configuration; not needed for other static hosts.
