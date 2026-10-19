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

- ~~**No conversation memory.**~~ *(now done: last 6 turns are sent)*
- ~~**No chat history persistence.**~~ *(now done: last 200 messages saved locally)*
- **Duck.ai answers are not extracted.** The provider was removed from the ensemble. The WebView JS that reads Duck.ai's reply is not written.
- **ChatGPT / Gemini / Qwen / Arena are not in the ensemble.** They need login and/or reCAPTCHA, and automating them breaks their terms. They are manual browser tabs only.
- **Automation tools do nothing.** No WhatsApp, Gmail, scheduler, or reminder backend exists.
- **No streaming.** The user waits for the slowest model (up to 30 s) before seeing anything.
- **No voice input/output.**
- ~~**No per-model view in the chat.**~~ *(now done: "Sources" on each bubble)*
- ~~**No settings to enable/disable providers.**~~ *(now done in Settings)*
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
| `useTor` fields | Removed. |
| `DuckAiProvider` always in the list, always `skipped` | Removed from the ensemble. |
| `ProviderAnswerSheet` not used | Wired to "Sources" on each assistant bubble. |
| Widget test used to expect the splash screen | **Replaced** with unit tests (the Tor gate now comes first). |

## 5. Status of the roadmap (update)

Status after the "anni add" pass. Verified by CI only, not on a phone:

| # | Item | Status |
|---|---|---|
| 1 | Conversation memory (last 6 turns, 1200 chars each) | Done |
| 2 | Answer sheet: "Sources" on each assistant bubble | Done |
| 3 | Streaming answers | Partly done. The synthesized answer streams token by token (SSE parser has unit tests). Per-model answers still arrive whole |
| 4 | Real Duck.ai JS extraction | Done, **experimental and off by default**. Hidden Tor WebView types the prompt and reads the reply. Selectors are guesses and unverified on a device. Check duck.ai's terms before enabling |
| 5 | LLM synthesis of the best answer (`kilo-auto/free`, Settings toggle, falls back to heuristic) | Done |
| 6 | Persistent chat history (`shared_preferences`, last 200 msgs) | Done. Not encrypted; history stays on the device |
| 7 | Settings: model toggles, synthesis toggle, custom endpoint (key in `flutter_secure_storage`) | Done |
| 8 | Tor status chip in chat app bar; re-verify on app resume | Done |
| 9 | Tor circuit rotation | Not done. Orbot's control port needs auth cookies that an app cannot safely read. Would need an embedded Tor (Arti) |
| 10 | Voice mode | Done. Mic button uses `speech_to_text`; speaker icon on answers uses `flutter_tts`. Needs device testing |
| 11 | Real automation backends | Not done. Needs your accounts and approvals (WhatsApp Business API, Gmail OAuth). See the questions below |
| 12 | Release pipeline | Partly done. `release.yml` builds a release APK on `v*` tags and attaches it to a GitHub release. It is signed with the debug key until you provide a keystore |
| 13 | Tests | Unit tests for orchestrator, memory, JSON, storage, config, SSE parsing. No widget/golden tests yet |
| 14 | Cleanup | Done. Removed `useTor` fields, `ai_service.dart`, `DuckAiProvider` |

## 6. Notes for the remaining items

- **Circuit rotation (9):** Orbot does not give apps a safe way to request a new circuit. Doing it properly means embedding Tor (Arti), which is larger and slower to start.
- **Automation backends (11):** need accounts and approvals on your side. WhatsApp Business API needs an approved business number. Gmail needs a Google Cloud OAuth client. Tell me which ones, and I can add the code behind a settings toggle.
- **Release signing (12):** needs a keystore only you should hold. Add it to the repo secrets (`KEYSTORE_B64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) and I will wire `signingConfigs`.

## 7. High-end features roadmap (original list, for reference)

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
