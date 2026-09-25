# Current state

The abandoned iOS focus-app idea was replaced by this web app. The user requested memorization support, simple English letters, pronunciation sound, modern styling, and addition to `speas0n/hanuman-chalisa`.

The implementation is static HTML/CSS/JS with 43 passages and 86 bundled synthetic Hindi audio clips. Progress is device-local. Read → hints → recall provides progressive text hiding; self-assessment schedules reviews. No microphone recognition or automatic pronunciation grading is claimed.

Run: `python3 -m http.server 4173 --directory dist`. Test: `npm test`.

Remaining validation: a physical iPhone/Safari run, and fluent human review of Awadhi pronunciation. Synthetic audio is explicitly labelled. No recurring notifications or background automation exists; reviews appear inside the app. No offline/PWA caching is implemented.

Future changes should preserve all 43 passages, text/audio alignment, local saved-state compatibility, and accessibility of the mobile Review action. Never bundle personal progress, credentials, model weights, or virtual environments into Git.
