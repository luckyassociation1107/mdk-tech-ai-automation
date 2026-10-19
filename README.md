# MDK Jarvis AI — Flutter AI Chat & Automation App

An AI chat / Jarvis-style assistant by **MDK Tech**. Every request goes through
**Tor** (fail-closed), is sent to several free AI models in parallel, and the app
shows the single best-judged answer.

> Full, honest breakdown: [docs/CAPABILITIES_AND_LIMITATIONS.md](docs/CAPABILITIES_AND_LIMITATIONS.md)

## ✨ What it does today

- 🧅 **Mandatory Tor (fail-closed)** — the app shows only a "Tor Required" gate until Orbot's SOCKS port (`127.0.0.1:9050`) is up **and** `check.torproject.org` confirms the traffic exits via Tor. No direct fallback.
- 🤖 **Free AI ensemble** — the question goes to 4 free Kilo Gateway models in parallel (no API key). A heuristic judge picks the best answer, and an optional synthesis step merges the answers into one (Settings toggle).
- 🧠 **Conversation memory** — the last 6 turns are sent with each question.
- 🔍 **Sources** — tap "Sources" on any answer to see every model's reply, its latency, and which one was picked.
- 💾 **Saved history** — the last 200 messages stay on the device across restarts.
- ⚙️ **Settings** — choose which free models to use, and add your own OpenAI-compatible endpoint (key kept in secure storage).
- 🛟 **Local fallback** — if no model answers, a built-in reply is shown instead of an error.
- 🌐 **Browser tab** — Tor-proxied WebView with presets (Duck.ai, ChatGPT, Gemini, Qwen, Arena, Kilo docs). You log in yourself; the app does not automate logins.
- 🔑 **Optional custom AI** — set it in Settings, or pass `--dart-define` values at build time.
- ⚙️ **Automation tab** — UI toggles only (demo). Not connected to WhatsApp / Gmail / scheduler yet.
- 🌙 **Material 3** — dark by default, switchable in Settings.

## 📁 Project structure

```
lib/
├── main.dart / app.dart
├── core/constants/app_constants.dart   # URLs, Kilo models, Tor ports, browser presets
├── core/theme/app_theme.dart
├── models/        chat_message, automation_tool, provider_result
├── providers/     chat_provider, theme_provider          (Provider + ChangeNotifier)
├── services/
│   ├── tor/            tor_service (gate + exit verify), tor_http_client (SOCKS5 HttpClient)
│   ├── providers/      ai_provider (base), openai_wire (shared call), kilo_provider,
│   │                   openai_compat_provider, local_mock_provider
│   ├── orchestrator/   multi_ai_orchestrator (fan-out + synthesis), judge_service, ensemble_config
│   └── storage/        settings_provider (prefs + secure key), chat_storage (history)
├── screens/       splash, tor_gate, home, chat, browser, automation, settings
└── widgets/       message_bubble, typing_indicator, provider_answer_sheet
docs/              capabilities & limitations, Tor design, no-login provider research
.github/workflows/ CI: analyze, test, debug APK build
```

## 🚀 Run it

Prerequisites: Flutter 3.22+ (CI uses stable), **Orbot** installed on Android and running in proxy mode.

```bash
git clone https://github.com/luckyassociation1107/mdk-tech-ai-automation.git
cd mdk-tech-ai-automation
flutter create --platforms=android .   # only if android/ is missing; keeps lib/
flutter pub get
flutter run
```

### Optional: add your own OpenAI-compatible model

Never commit keys. Pass them at build/run time:

```bash
flutter run \
  --dart-define=AI_API_KEY=your_key \
  --dart-define=AI_API_URL=https://api.openai.com/v1/chat/completions \
  --dart-define=AI_MODEL=gpt-4o-mini
```

Other build-time overrides: `KILO_API_KEY`, `KILO_GATEWAY_URL`.

## ✅ CI

`.github/workflows/flutter-ci.yml` runs `flutter analyze`, `flutter test`, and builds a debug APK (uploaded as an artifact). It also patches one deprecated ProGuard call in `flutter_inappwebview_android` 1.1.3 — remove that step once the plugin is fixed upstream.

## 🧪 Tests

```bash
flutter analyze
flutter test
```

Current tests cover the orchestrator (local fallback dropped when a real AI answers, history passed to models), the judge, chat memory, message JSON, custom-endpoint config, and chat storage. Tor and WebView behaviour need a device test.

## 🗺️ Roadmap

Still open (see [docs/CAPABILITIES_AND_LIMITATIONS.md](docs/CAPABILITIES_AND_LIMITATIONS.md), section 5): streaming answers, Duck.ai answer extraction, Tor circuit rotation, voice mode, real automation backends, release signing.

---

Made with Flutter • MDK Tech
