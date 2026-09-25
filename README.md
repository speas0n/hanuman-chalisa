# Hanuman Chalisa practice

A mobile-friendly web app to help you remember the Hanuman Chalisa, one passage at a time.

## Use it

1. **Read:** listen to each line and repeat it aloud.
2. **Hints:** alternate words disappear. Tap a hidden word for help.
3. **Recall:** try both lines without the text, reveal the answer, then rate yourself.

Includes all 40 verses, two opening dohas, and the closing doha. Text uses simple English letters. Every line has a bundled pronunciation clip, with slower playback and three-repeat practice. Progress is saved locally in your browser; it does not sync between devices. Successful recalls schedule review in 1, 3, 7, then 14 days. Difficult passages remain due today. Repeating a success on the same day does not increase its review stage.

## Run locally

Requires Python 3. No application packages or build step.

```sh
python3 -m http.server 4173 --directory dist
```

Open http://localhost:4173. Serve the `dist` directory on any static HTTPS host to use it on your phone. On iPhone, open the hosted URL in Safari and use Share → Add to Home Screen if desired. The app needs a connection for audio; offline mode is not implemented.

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
