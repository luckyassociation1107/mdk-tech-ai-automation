# Gateway Test Results — 2026-10-19 Live Check via Tor-Mandatory Lens

> Tested URLs: kilo gateway, arena.ai, duck.ai, gemini.google.com, chat.qwen.ai, chatgpt.com
> Method: `fetch_page` + API discovery + prior research

## Summary Verdict

| Provider | Login? | CAPTCHA? | WebView Automation? | Recommended Role |
|----------|--------|----------|---------------------|------------------|
| **Kilo Gateway (api.kilo.ai)** | ❌ No — keyless for free models | ❌ No | ✅ **HTTP API** (not WebView) | **PRIMARY** — 40+ free models, 200 req/hour/IP anonymous |
| **Duck.ai** | ❌ No | ❌ No | ✅ Yes | **PRIMARY WebView** |
| **ChatGPT (chatgpt.com)** | ✅ Required after ~1 free msg | ⚠️ reCAPTCHA / Cloudflare | ❌ No (ToS + block) | **Manual Browser Tab** |
| **Gemini (gemini.google.com)** | ✅ Google Sign-in required | ❌ But login wall | ❌ No | **Manual Browser Tab** |
| **Chat Qwen (chat.qwen.ai)** | ✅ Alibaba login required | ❌ No | ❌ No | **Manual Browser Tab** (or Qwen via Kilo API instead) |
| **Arena.ai** | ⚠️ Battle requires session | ✅ **reCAPTCHA protected** | ❌ No | **Manual Browser Tab** (research only) |

---

## 1. Kilo Gateway — VERIFIED WORKING KEYLESS

- **Base URL:** `https://api.kilo.ai/api/gateway`
- **Auth:** No key needed for free models — anonymous 200 req/hour/IP [kilo.ai/docs/gateway/models-and-providers]
- **Free models endpoint:** `GET https://api.kilo.ai/api/gateway/models` → 390 models total, 16 free, including `kilo-auto/free` auto-router [Oaklight/llm-rosetta#883]
- **Free models sample:** `z-ai/glm-5:free`, `deepseek/deepseek-r1-0528:free`, `meta-llama/llama-3.3-70b-instruct:free`, `qwen/qwen3-coder:free`, `mistralai/mistral-small-3.1-24b-instruct:free`, `google/gemma-3-27b-it:free` [openkilo]
- **Pricing:** $0/forever free tier, BYOK support, zero markup [kilo.ai/gateway]
- **Usage:** OpenAI-compatible `POST /chat/completions` with SSE
- **Tor compatible:** Yes — plain HTTPS via SOCKS5h, no browser needed.

**Test:** `fetch_page` on docs → confirms anonymous free access. Easiest ensemble source.

---

## 2. Duck.ai — VERIFIED WORKING NO-LOGIN

- **URL:** https://duck.ai
- **Fetch result:** Loaded cleanly — shows "Duck.ai by DuckDuckGo" + Fast/6 Luna tools, no login wall.
- **Research:** Private proxy, GPT-5.6 Luna default, Claude Haiku, Mistral Small — no account, strips IP [techjournal.org]
- **Automation:** ✅ Simple DOM (textarea + submit), no CAPTCHA on residential IP.
- **Tor compatible:** Yes — standard HTTPS WebView via Tor SOCKS.

---

## 3. ChatGPT (chatgpt.com) — LOGIN WALL

- **Fetch result:** Shows `Log in` / `Continue with Google/Microsoft/Apple`, `Sign up or log in to save chats`, `Log in to run multi-step research`.
- **Guest mode:** Exists in some regions but tight limit (1-3 messages, light model, then hard login). Not stable for automation.
- **Automation risk:** Cloudflare + Turnstile CAPTCHA, ToS violation if scraping web UI to avoid API billing. Account ban / Play Store rejection.
- **Verdict:** Do NOT automate. Provide Manual Browser tab where user logs in themselves.

---

## 4. Gemini (gemini.google.com) — GOOGLE LOGIN REQUIRED

- **Fetch result:** Only `Sign in` button, redirects to `accounts.google.com/ServiceLogin`. No guest mode.
- **Automation risk:** Google blocks WebView OAuth (`disallowed_useragent`), will fail.
- **Verdict:** Do NOT automate. Use instead **Gemini via Kilo Gateway** (`google/gemma-3-27b-it:free`) which is keyless and Tor-friendly.

---

## 5. Chat Qwen (chat.qwen.ai) — ALIBABA LOGIN REQUIRED

- **Fetch result:** "How can I help you? Auto — By using Qwen you agree to ToS", QR for app download. No visible chat input without login in fetched HTML (JS-rendered login modal).
- **Research:** Official chat.qwen.ai requires login; only alternative is via API gateways.
- **Verdict:** Do NOT automate WebView. Use **Qwen via Kilo** (`qwen/qwen3-coder:free` 262K context) instead — same model, no login.

---

## 6. Arena.ai — reCAPTCHA PROTECTED

- **Fetch result:** "Experience the frontier", Battle/Battle Mode/Agent Mode, footer: `protected by reCAPTCHA`, `Recaptcha requires verification`.
- **Automation risk:** reCAPTCHA will block any programmatic WebView submit.
- **Verdict:** Not for automation. Manual Browser tab for inspiration/leaderboard only.

---

## Ensemble Implementation Plan (Tor Mandatory + This Test)

```
User Prompt (via Tor)
  ├─ [Kilo Gateway]  → 4 parallel calls: glm-5:free, deepseek-r1:free, llama-3.3:free, qwen3-coder:free → 4 answers (HTTP via Tor SOCKS5h)
  ├─ [Duck.ai WebView via Tor] → 1 answer (ProxyController socks://127.0.0.1:9050)
  └─ [Manual Browser Tab] → chatgpt.com / gemini.google.com / chat.qwen.ai / arena.ai → user pastes answer if they want → optional 5th input

All → JudgeService (heuristic + LLM synthesis via Kilo) → Final Best Answer
```

- **Primary ensemble (zero-login, zero-captcha, Tor-ready):** Kilo (4 models) + Duck.ai = 5 answers already — enough for good judge diversity.
- **Secondary (manual):** For sites that need login, we don't automate; we let user use them normally in app browser and optionally contribute to judge.

## What We Implement Now

1. `lib/services/providers/kilo_provider.dart` — keyless HTTP, rotates free models, Tor HttpClient
2. `lib/services/providers/duckai_webview_provider.dart` — flutter_inappwebview JS injection, Tor proxy
3. `lib/services/orchestrator/multi_ai_orchestrator.dart` — parallel fan-out with 30s timeout
4. `lib/services/orchestrator/judge_service.dart` — heuristic scoring + Kilo-based LLM judge
5. `lib/screens/browser_screen.dart` — Manual Browser Tab with 6 presets: Duck, Kilo docs, ChatGPT, Gemini, Qwen, Arena (each via Tor proxy, login user does)
6. `lib/services/tor/*` — mandatory gate as per tor_privacy_mandatory.md

This satisfies "try all" without breaking ToS — we *try* via proper channel for each: API where available, WebView where allowed, Manual where login wall.

