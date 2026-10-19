# No-Login, No-CAPTCHA AI Websites — Research Report
### For MDK Jarvis AI (Flutter WebView Ensemble + Judge)

> Date: 2026-10-19 | Context: API-less WebView automation + Multi-AI Judge
> Goal: `playwright automation type in app webview automation` — multiple AIs nundi answers techi, okka best answer ni judge chesi ivvadam.

---

## 1. TL;DR — Best Picks for Your Idea

| Priority | Website / API | Login? | CAPTCHA? | Why useful for you |
|---|---|---|---|---|
| **#1** | **Duck.ai (DuckDuckGo)** — duck.ai | ❌ No | ❌ No (normal IP) | Multi-model in one page (GPT-5 mini/nano, Claude 4.5 Haiku, Mistral Small, Llama), privacy proxy, daily cap but generous. Cleanest no-login experience in 2026. |
| **#2** | **DeepSeek** — chat.deepseek.com | ❌ No | ❌ No | ~500 msgs/hour, frontier coding reasoning, no account needed |
| **#3** | **HuggingChat** — huggingface.co/chat | ❌ No | ❌ No | 100s of open-source models (Llama, Mistral, Qwen...), transparent |
| **#4** | **Pollinations / OVHcloud / Kilo Gateway** — *keyless APIs* | ❌ No | ❌ No | **Zero login, zero key** — anonymous per-IP rate limit (~200 req/hour). Best true "API-less" backend for app. |
| **#5** | **Perplexity AI** — perplexity.ai | ❌ Guest mode | ❌ No | Research with citations, 5-10 free searches/day without login |
| **#6** | **Microsoft Copilot** — copilot.microsoft.com | ❌ Partial | ❌ No | GPT-4o + web search, works without Microsoft account for short sessions |
| **#7** | **Le Chat by Mistral** — chat.mistral.ai | ❌ No (guest) | ❌ No | Fast writing/coding, European privacy |
| **#8** | **NanoGPT** — nano-gpt.com | ❌ No | ❌ No | 1000+ models pay-as-you-go from $1, crypto from $0.10, no account |

> **Avoid for WebView automation:** ChatGPT, Claude, Gemini official — all require login (and show CAPTCHA/bot checks if you try to automate). Automating them = ToS violation + ban risk.

---

## 2. Detailed Breakdown

### A. TRUE No-Login + No-CAPTCHA (Safe for WebView)

#### 1. Duck.ai by DuckDuckGo
- URL: https://duck.ai
- Login: None. Open and chat.
- CAPTCHA: No on normal residential/mobile IP. May show Cloudflare only on VPN/Tor abuse.
- Models: GPT-5.6 Luna (default 2026), Claude 4.5 Haiku, GPT-5.4 mini/nano, Mistral Small, Gemma 4. Switch mid-chat.
- Limits: Generous daily cap (resets daily).
- Privacy: DuckDuckGo strips IP before forwarding to model provider, chats not used for training.
- WebView stability: **HIGH** — simple DOM, no login modal.

#### 2. DeepSeek
- URL: https://chat.deepseek.com
- Login: None.
- CAPTCHA: No (anti-bot threshold ~500 msgs/hour).
- Models: DeepSeek V3.2 / R1 reasoning.
- Best for: Coding, maths, long-form analysis. No upsell (they monetize API).
- WebView stability: **HIGH**

#### 3. HuggingChat
- URL: https://huggingface.co/chat
- Login: None.
- CAPTCHA: No.
- Models: Llama 3.x, Mistral, Qwen2.5, DeepSeek, 100k+ OSS models, web-search toggle.
- WebView stability: **MEDIUM-HIGH** — open source, fewer bot checks.

#### 4. Perplexity AI (Guest Mode)
- URL: https://www.perplexity.ai
- Login: Optional — guest works for basics.
- CAPTCHA: No.
- Limits: ~5-10/day free searches, then asks for login. Citations included.
- Best for: Research where source links matter.

#### 5. Microsoft Copilot
- URL: https://copilot.microsoft.com
- Login: Partial — works without Microsoft account for short sessions.
- CAPTCHA: No (Edge/Bing context).
- Models: GPT-4o / GPT-5 class with Bing grounding.
- Note: Long chats nudge to sign in. Good fallback, not primary.

#### 6. Le Chat by Mistral
- URL: https://chat.mistral.ai
- Login: Guest allowed, account adds history.
- CAPTCHA: No.

#### 7. Perchance AI / zalt.me WebLLM (Truly Offline)
- URL: https://perchance.org/ai-chat , https://zalt.me/tools/free-ai-chat-online
- How: Runs model *in browser* via WebGPU (Llama 3.2, Qwen3, Phi 3.5, DeepSeek R1 135M-8B). Nothing sent to server.
- Login/CAPTCHA: Impossible — no server.
- Best for: Privacy demo, fallback when offline.

### B. Keyless APIs (No Login, No API Key — Perfect for "API-less" App Backend)

These are NOT websites to scrape, but *APIs that need no key at all* — ideal for Flutter `http` call without asking user for keys.

| Provider | Keyless? | RPM | Good for |
|---|---|---|---|
| Pollinations | Yes | Anonymous per IP | Text, image, voice |
| OVHcloud AI Endpoints | Yes | 17 routes anonymous | Chat, embeddings, Whisper |
| Kilo Gateway | Yes | ~200 req/hour per IP | Chat |
| Free.ai (free.ai/chat) | Yes (6k tokens/day no signup) | 6k/day | Quick chat |

> If you truly want "api less" but stable, use these. WebView scraping kante 10x stable.

### C. Free-Tier APIs (One-Time Free Key, No Credit Card, End-User Needs No Login)

Your app's Settings page lo *you* (developer) or *user* okka sari free key paste chesthe, app users malli login cheyyalsina avasaram ledhu.

| Provider | Free Models | Limits | Card? | OpenAI Compatible? |
|---|---|---|---|---|
| Google AI Studio (Gemini) | Gemini 2.5 Flash/Pro, Gemma 4 | 5-15 RPM, 20-1500/day, 1M context | No | Partial |
| Groq | Llama 3.3 70B, Mixtral, Qwen3, GPT-OSS 120B | 30 RPM, 1000 RPD, 200k TPD | No | Yes |
| OpenRouter :free | 20+ models (DeepSeek R1, Llama 4, Qwen3) | 20 RPM, 50/day → 1000/day after $10 topup | No | Yes |
| Hugging Face Inference | 100k+ open models | $0.10/month free (tiny) | No | Yes |

Most generous: **Gemini** (unlimited Flash) + **Groq** (fastest) + **OpenRouter** (widest choice).

---

## 3. What WILL Show CAPTCHA / Login Wall (Avoid)

| Site | Reality |
|---|---|
| ChatGPT (chatgpt.com) | Logged-out mode exists in some regions but tight limits + light model (GPT-5 mini class), CAPTCHA/Tor blocks. Full = login required. |
| Claude (claude.ai) | Account required always. |
| Gemini (gemini.google.com) | Google account required. |
| Poe, T3.chat, TypingMind | Account required even for free tier. |
| Wrapper sites like "aifreeforever.com" claiming "no login, all models" | Often hide behind ads, rate limits change daily, violate provider ToS — not stable for production. |

---

## 4. Recommended Architecture for Your Requirement

```
User Question
     |
     +---> [ Pollinations Keyless ] ---> Ans 1 \
     +---> [ Duck.ai WebView JS ] -----> Ans 2  \
     +---> [ DeepSeek WebView JS ] ----> Ans 3   +---> JudgeService ---> Final Best Answer
     +---> [ HuggingChat WebView JS ] -> Ans 4  /         (heuristic + LLM synthesis)
     +---> [ Local Mock Fallback ] ----> Ans 5 /
```

**Judge logic (Heuristic + LLM-as-Judge):**
1. Score each answer: relevance (keyword overlap), length sanity, structure (lists/code blocks), consensus (how many AIs agree), freshness (if web search).
2. If at least one LLM API is available, feed: "You are Judge. User asked: {q}. Here are 4 answers... Pick best andsynthesize final improved answer in Telugu/English as needed."
3. Show: Final answer on top + expandable "Compare all 4 answers" sheet.

**WebView Automation Technique (Flutter):**
- Package: `flutter_inappwebview` (JS injection more powerful than `webview_flutter`)
- For each provider: `inAppWebViewController.evaluateJavascript("document.querySelector('textarea').value='...'; document.querySelector('button[type=submit]').click()")`
- Detect completion: poll `document.body.innerText` until streaming stops (no new tokens for 2s) or provider's "stop" button disappears.
- Timeout: 30s per provider, then mark as failed.
- Run providers **sequentially** in hidden WebViews (or parallel with multiple offscreen WebViews) — sequential is more stable on low RAM phones.

**Why NOT pure Playwright-style hidden automation for ChatGPT/Gemini/Claude?**
- Cloudflare Turnstile / Arkose Labs CAPTCHA triggers on headless/emulated browsers.
- Google blocks WebView OAuth ("disallowed_useragent").
- DOM selectors break weekly — maintenance hell.
- Violates ToS: OpenAI, Anthropic, Google prohibit scraping web UI to bypass API billing — account ban + Play Store rejection risk.

**Safe compromise we implement:**
- Ensemble over *allowed* no-login sites (Duck.ai, DeepSeek, HuggingChat) + keyless APIs (Pollinations) + user-provided free API keys (Gemini/Groq/OpenRouter — user enters their own free key in Settings, so your app never pays).
- Plus optional **Manual Browser Tab**: app lo `webview_flutter` tab where user can manually open chatgpt.com/gemini/claude with their own login and copy-paste — we don't automate it.

---

## 5. Implementation Plan (Next Steps)

1. Add deps: `flutter_inappwebview`, `http`, `provider` (already), `shared_preferences` for key storage.
2. Create `lib/services/providers/`:
   - `ai_provider.dart` (interface)
   - `pollinations_provider.dart` (keyless HTTP)
   - `duckai_provider.dart` (WebView JS)
   - `deepseek_provider.dart` (WebView JS)
   - `huggingchat_provider.dart` (WebView JS)
   - `gemini_provider.dart`, `groq_provider.dart`, `openrouter_provider.dart` (free API HTTP, optional)
3. Create `lib/services/orchestrator/`:
   - `multi_ai_orchestrator.dart` — parallel fan-out with timeout
   - `judge_service.dart` — heuristic scoring + optional LLM synthesis
4. Update `chat_screen.dart`: show "Consulting 4 AIs..." progress, then final judged answer + "View all answers" bottom sheet.
5. Update `settings_screen.dart`: fields to paste free API keys (stored locally, never committed), toggle which providers to use, toggle "Manual Browser Mode".
6. Add `lib/screens/browser_screen.dart`: simple WebView browser for manual ChatGPT/Gemini access.

All API keys via `--dart-define` or `SharedPreferences` — never hard-coded, never pushed to GitHub.

---

## Sources
- Duck.ai best overall no-signup, private anonymous [3](https://techjournal.org/best-free-ai-chatbots-no-sign-up) [8](https://zalt.me/tools/free-ai-chat-online) [23](https://www.makeuseof.com/duckduckgo-gpt-56-luna-free/)
- DeepSeek no signup ~500 msgs/hour, strong coding [3](https://techjournal.org/best-free-ai-chatbots-no-sign-up) [15](https://perspectiveai.xyz/best-free-ai-chatbot-2026/)
- HuggingChat open-source no login [5](https://kugie.app/blog/best-free-ai-chatbots-with-no-sign-up) [16](https://kugie.app/blog/best-free-ai-chatbots-with-no-sign-up-needed)
- Perplexity guest mode 5-10/day [4](https://chatboq.com/blogs/free-ai-chatbots-no-login) [13](https://askaichat.app/blog/ai-chat-no-sign-up)
- Microsoft Copilot GPT-4o without login but partial [4](https://www.kaily.ai/blog/best-free-ai-chatbot-with-no-sign-up) [14](https://aadhunik.ai/blog/free-ai-tools-like-chatgpt-without-login/)
- Le Chat Mistral guest [14](https://aadhunik.ai/blog/free-ai-tools-like-chatgpt-without-login/)
- Keyless APIs: Pollinations/OVHcloud/Kilo 200 req/hour anonymous [8](https://0xzr.github.io/freellmpool/free-llm-api-providers-list.html)
- Free LLM APIs: OpenRouter 20 RPM 50/day, Groq 30 RPM 1000/day, Gemini generous no card [1](https://openrouter.ai/blog/tutorials/free-llm-apis-compared/) [2](https://freeapihub.com/blog/best-free-ai-apis-developers) [3](https://klymentiev.com/blog/free-llm-api) [6](https://blog.laozhang.ai/en/posts/free-ai-api-tiers-compared)
- CAPTCHA/login risks and ChatGPT logged-out limits [13](https://askaichat.app/blog/ai-chat-no-sign-up) [2](https://aifreeforever.com/chat)

