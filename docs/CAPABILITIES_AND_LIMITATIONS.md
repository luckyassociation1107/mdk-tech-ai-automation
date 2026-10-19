# MDK Jarvis AI — Capabilities, Limitations & Roadmap

Status as of commit `f22fcdd` + the review commit that adds this file.
Written from a full read of the repo. Anything marked **UNVERIFIED** has not been run on a device.

---

## 1. What the app can do (working in code)

| Area | What works | Where |
|---|---|---|
| Tor gate | Blocks the whole app until Orbot SOCKS `127.0.0.1:9050` is open **and** `check.torproject.org` (fetched through that SOCKS port) returns `IsTor=true`. Result cached 5 min. | `services/tor/tor_service.dart`, `screens/tor_gate_screen.dart` |
| Tor HTTP | All `HttpClient`s built by `TorHttpClient.create()` route through SOCKS5 via `socks5_proxy`. | `services/tor/tor_http_client.dart` |
| Chat ensemble | One question → 4 Kilo free models in parallel (30 s cap each) → heuristic judge → one answer. | `services/orchestrator/*`, `services/providers/kilo_provider.dart` |
| Judge | Scores answers on length, structure, latency, and word overlap with other answers. Picks one. | `services/orchestrator/judge_service.dart` |
| Fallback | If no real model answers, a local reply is shown (never an error screen). Local reply is dropped whenever a real answer exists. | `local_mock_provider.dart`, `multi_ai_orchestrator.dart` |
| Custom model | If `AI_API_KEY` is given at build time, an OpenAI-compatible endpoint joins the ensemble. | `openai_compat_provider.dart` |
| Browser | Tor-proxied `InAppWebView` with 6 presets. Does **not** load a page until the proxy override is applied (fail-closed). | `screens/browser_screen.dart` |
| Theme | Material 3, dark default, toggle in Settings. | `providers/theme_provider.dart` |
| Automation tab | Toggle UI only. Each toggle shows a "demo, backend not connected" message. | `screens/automation_screen.dart` |
| CI | GitHub Actions: `pub get`, `analyze`, `test`, debug APK artifact. Last run green. | `.github/workflows/flutter-ci.yml` |

## 2. What the app cannot do (yet)

- **No conversation memory.** Each question is sent alone. Follow-ups like "explain that more" do not work.
- **No chat history persistence.** Restarting the app clears everything. `ChatMessage` already has `toJson/fromJson`, but nothing saves it.
- **Duck.ai answers are not extracted.** `DuckAiProvider` always returns `skipped`. The WebView JS that reads Duck.ai's reply is not written.
- **ChatGPT / Gemini / Qwen / Arena are not in the ensemble.** They need login and/or reCAPTCHA, and automating them breaks their terms. They are manual browser tabs only.
- **Automation tools do nothing.** No WhatsApp, Gmail, scheduler, or reminder backend exists.
- **No streaming.** The user waits for the slowest of 4 models (up to 30 s) before seeing anything.
- **No voice input/output.**
- **No per-model view in the chat.** `ProviderAnswerSheet` widget exists but is not wired to any screen. The user cannot see which models answered.
- **No settings to enable/disable providers or pick Kilo models.** Model list is a compile-time constant.
- **No iOS Tor support.** Android WebView proxy override needs Android 10+, and the Tor gate on iOS only checks the socket. The Browser tab blocks itself on iOS.
- **No Tor identity rotation** (new circuit on demand).

## 3. Known limitations and risks

### Quality
- **Judge is heuristic.** It rewards length, formatting, and agreement with other answers. It does not check correctness. Four wrong answers that agree can beat one right answer.
- **`max_tokens: 600`** in `KiloProvider`. Long answers get cut off mid-sentence.
- **Kilo model IDs come from third-party lists** (`z-ai/glm-5:free`, `deepseek/deepseek-r1-0528:free`, `meta-llama/llama-3.3-70b-instruct:free`, `qwen/qwen3-coder:free`). **UNVERIFIED** against the live catalogue. A model ID that disappears makes that slot fail silently.

### Free-tier limits
- Kilo anonymous: **200 requests per hour per IP.** Heavy use gets rate-limited, and Tor exits share IPs, so limits can hit sooner.
- Free models can be removed or change without notice.

### Tor
- **Tor is checked at launch and before each chat message** (cached 5 min), **not continuously.** If Orbot stops mid-session, the next message is blocked. An in-flight request can still fail with a generic error.
- **Tor is slow.** Latency is 2–10× normal. The 30 s per-model timeout may trigger often.
- **Some sites block Tor exits.** CAPTCHAs or 403s are expected on the browser tab and sometimes on Kilo.
- **The WebView ProxyController is global** to the WebView process. Any WebView in the app uses Tor, which is what we want, but it also means no WebView can be used without Tor.
- **Orbot must run in proxy mode.** VPN mode is a different setup and is not tested.

### Privacy (what Tor does and does not cover)
- Tor hides the device IP from the AI providers. It does **not** hide the prompt text, which each provider receives.
- Kilo, Duck.ai, and any custom endpoint see the prompt. Do not send secrets.
- The app stores nothing on disk, so there is no history to leak. There is also no local history to recover.

### Build & platform
- **Not compiled on-device.** CI compiles and runs analysis and unit tests. Nobody has run the app on a phone yet.
- **Patched dependency.** `flutter_inappwebview_android` 1.1.3 has a deprecated ProGuard call that breaks AGP builds. CI patches it in the pub cache. Remove when upstream is fixed.
- **Debug APK only.** No release signing config, no ProGuard rules, no store listing.
- **`socks5_proxy` API** is used as `SocksTCPClient.assignToHttpClient(io, [ProxySettings(...)])`. **UNVERIFIED** against the 2.x API surface in this repo's lock resolution — CI would catch a compile error here.

### Legal / ToS
- Using free-tier APIs is allowed under those providers' terms, but **check each provider's current terms** before a public release.
- WebView automation of third-party web UIs (Duck.ai) is a grey area. The app currently does not automate it; it only loads pages.
- Nothing in the app bypasses logins, CAPTCHAs, or rate limits.

## 4. Code-quality notes from the review

| Item | Status |
|---|---|
| `ai_service.dart` (old single-provider service) | **Removed** — dead code after the orchestrator change. |
| `TOR_MANDATORY_README.md` said "direct ga chat open avadu" and "direct ki velladu" | **Fixed** — contradicted fail-closed. |
| Mock replies said "enable Kilo in Settings" but no such setting exists | **Fixed.** |
| Settings "AI connection" said "local demo mode" | **Fixed** to show the real state. |
| Tor check only tested that the port was open | **Fixed** — now verifies `IsTor=true` through the proxy. |
| Automation toggles said "switched ON" with no effect | **Fixed** — message now says demo, backend not connected. |
| `KiloProvider.useTor` / `OpenAICompatProvider.useTor` fields | Unused. Routing is always Tor. Kept for now; remove in cleanup. |
| `DuckAiProvider` always in the list, always `skipped` | Harmless, but wasteful. Leave until WebView extraction exists. |
| `ProviderAnswerSheet` not used | Wire it up (see roadmap). |
| Widget test used to expect the splash screen | **Replaced** with unit tests (the Tor gate now comes first). |

## 5. High-end features roadmap

Ordered by value vs. effort. Items 1–4 are the most important.

1. **Conversation memory.** Keep the last N turns, send them with each question. Cap by character count. Small change in `ChatProvider` and `KiloProvider`.
2. **Show the winner and all answers.** Long-press (or tap "Sources") on an assistant bubble to open `ProviderAnswerSheet` with each model's answer and latency.
3. **Streaming answers.** Kilo supports OpenAI-style SSE. Show the first model that starts streaming; keep the others in the sheet.
4. **Real Duck.ai extraction.** Inject JS into the Browser WebView, read the last answer node, push it into `DuckAiProvider.submitWebViewAnswer`. Needs a hidden WebView for ensemble use.
5. **LLM judge.** `JudgeService.synthesizeWithLlm` exists. Use it when ≥2 answers succeed. Use the cheapest free model. Fall back to the heuristic on failure.
6. **Persist chat history** with `shared_preferences` (or `sqflite`). Encrypt with `flutter_secure_storage` for the key. Add "clear history" that also wipes it.
7. **Settings: providers.** Toggle each Kilo model, set custom key/URL in-app (stored in secure storage, not `--dart-define`), and test-connect button.
8. **Tor status indicator** in the app bar, plus a "re-verify" action. Re-check when the app resumes from background.
9. **Tor circuit rotation** via Orbot's control port, if it can be exposed safely.
10. **Voice mode.** `speech_to_text` for input, `flutter_tts` for reading the answer aloud.
11. **Real automation backends.** One at a time: Gmail (OAuth), WhatsApp Business API (needs approved account), scheduled reminders with `flutter_local_notifications`.
12. **Release pipeline.** Signed release APK/AAB in CI, `minifyEnabled` with ProGuard rules, versioning from git tags.
13. **Test coverage.** Mock the Tor socket probe and the HTTP client; golden tests for chat and gate screens; an integration test on an Android emulator in CI.
14. **Cleanup.** Remove unused `useTor` fields; remove `DuckAiProvider` from the list until item 4 is done.
