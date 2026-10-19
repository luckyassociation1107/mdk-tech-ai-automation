# MDK Jarvis AI — Flutter AI Chat & Automation App

An AI Chat / Jarvis-style assistant app built with **Flutter** by **MDK Tech**.
It works out of the box in **local demo mode** (built-in mock Jarvis, no API
key needed) and can be connected to a real AI model with a single command.

## ✨ Features

- 🤖 **AI Chat** — chat bubbles, "Jarvis is typing…" indicator, suggestion chips, clear-chat
- ⚙️ **Automation Tools** — WhatsApp Auto-Reply, Email Automation, Social Media Scheduler, Task Reminders, Lead Follow-Up, AI Study Planner (toggle on/off)
- 🌙 **Dark / Light theme** — Material 3, switchable in Settings (dark by default)
- 🧱 **Clean structure** — `core / models / services / providers / screens / widgets` using Provider
- 🔌 **Real AI ready** — plug in any OpenAI-compatible API via `--dart-define` (no keys in code)

## 📁 Project structure

```
lib/
├── main.dart                  # App entry point + Provider setup
├── app.dart                   # MaterialApp, theme wiring
├── core/
│   ├── constants/app_constants.dart
│   └── theme/app_theme.dart
├── models/
│   ├── chat_message.dart
│   └── automation_tool.dart
├── services/
│   └── ai_service.dart        # Real API call + local mock fallback
├── providers/
│   ├── chat_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── home_screen.dart       # Bottom navigation
│   ├── chat_screen.dart
│   ├── automation_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── message_bubble.dart
    └── typing_indicator.dart
```

## 🚀 How to run

> This repo contains the complete Dart source (`lib/`, `pubspec.yaml`, tests).
> If the platform folders (`android/`, `ios/`) are not present yet, generate
> them once with `flutter create .` — it will **not** overwrite `lib/`.

```bash
git clone https://github.com/luckyassociation1107/mdk-tech-ai-automation.git
cd mdk-tech-ai-automation

# 1) Generate android/ios/web folders (safe, keeps lib/ as-is) — run once if missing
flutter create .

# 2) Install dependencies
flutter pub get

# 3) Run (local demo mode — no key needed)
flutter run
```

### 🔑 Connect a real AI (optional)

Never commit an API key. Pass it at run/build time instead:

```bash
flutter run \
  --dart-define=AI_API_KEY=your_key_here \
  --dart-define=AI_API_URL=https://api.openai.com/v1/chat/completions \
  --dart-define=AI_MODEL=gpt-4o-mini
```

Any OpenAI-compatible endpoint works. If the API call fails, the app
automatically falls back to the local mock replies.

## 🧪 Tests

```bash
flutter test
flutter analyze
```

## 🗺️ Roadmap ideas

- Save chat history locally (Hive / SharedPreferences)
- Voice input & text-to-speech (Jarvis voice mode)
- Firebase login
- Connect each Automation tool to its real backend API
- Gemini / other model providers in `AiService`

---

Made with Flutter • MDK Tech
