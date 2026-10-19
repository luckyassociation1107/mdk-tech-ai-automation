# Tor Privacy — MANDATORY Mode (MDK Jarvis AI)

> User requirement: **Tor privacy mandatory** — app must route *all* traffic via Tor, no direct fallback.

## 1. What "Mandatory" Means Technically

- `FAIL CLOSED` — Tor proxy down ayithe app **block** avvali, direct internet ki vellakudadhu.
- HTTP (AI providers: Gemini/Groq/OpenRouter/Pollinations) → SOCKS5 127.0.0.1:9050 via Tor circuit
- WebView (Duck.ai / DeepSeek / HuggingChat automation) → same proxy via `ProxyController`
- DNS kuda Tor exit node deggare resolve avvali (`socks5h://` semantics), local WiFi observer ki domain kuda kanapadakudadhu.

Orbot does exactly this: SOCKS 127.0.0.1:9050 + HTTP 127.0.0.1:8118 expose chesthundi [guardianproject].

## 2. Architecture — How We Enforce It

```
User opens app
    ↓
TorGuard (singleton service) checks:
  ├─ Is Orbot SOCKS port reachable? (socket connect 127.0.0.1:9050 with 2s timeout)
  ├─ Probe: GET https://check.torproject.org/api/ip via SOCKS → verify exit IP != real IP
  └─ If FAIL → Show BLOCKING screen: "Tor Required — Start Orbot" [Open Orbot / Retry]

If PASS:
  ├─ HttpClient layer: SocksTCPClient.assignToHttpClient(client, [ProxySettings(127.0.0.1, 9050)])
  ├─ WebView layer: ProxyController.setProxyOverride(proxyRules: ["socks://127.0.0.1:9050"])
  └─ All AI ensemble + judge calls go through above clients only

On dispose / app pause:
  → clearProxyOverride() is NOT called (we stay fail-closed; we keep override)
  → Optionally new circuit: send NEWNYM to ControlPort 9051 if enabled
```

**Key enforcement:**
- App lo `HttpOverrides.global` or custom `TorHttpClientFactory` thappa direct `HttpClient()` create cheyyam — lint rule.
- WebView create ayye mundu `ProxyController` set chesi tharvata ne URL load.
- `bypassRules: []` — empty, so no site bypasses proxy. For safety, `addDirect()` petamu.

## 3. Package Choices (Verified via Research)

| Layer | Package | Why |
|-------|---------|-----|
| HTTP via Tor | `socks5_proxy` or `socks_socket` | Dart HttpClient ni SOCKS5 ki assign cheyyachu: `SocksTCPClient.assignToHttpClient(client, [ProxySettings(loopback, 9050)])` |
| WebView via Tor | `flutter_inappwebview` | **Only** package with per-app proxy on Android 10+ via `ProxyController.setProxyOverride()` — official `webview_flutter` lo ledu |
| Embedded Tor (optional V2) | `flutter_tor` (Arti Rust) | Young but promising; 10-15 MB APK increase, bootstrap 15-40s. V1 ki recommend kadu |
| External Tor (V1) | **Orbot** by Tor Project | Stable, 10M+ installs, 17.9.x with Tor 0.4.9.x, SOCKS 9050 + HTTP 8118 |

> Research confirms: `webview_flutter` proxy support ledu, `flutter_inappwebview` ProxyController Android 10+ lone work avuthundi — so V1 Android-first.

## 4. V1 Implementation Plan (External Orbot — Recommended)

**Why External Orbot for mandatory mode?**
- No extra APK size, no battery drain from second tor daemon
- Orbot already handles bridges (obfs4, Snowflake), censorship circumvention
- System VPN slot ni Orbot VPN mode vadakunda, **Proxy mode (Power User Mode)** vadutham — app only routes via 9050, so user inka vere VPN vadukovachu
- Embedded Arti still maturing, bootstrap failures common

**Steps:**
1. `pubspec.yaml` add:
   ```yaml
   flutter_inappwebview: ^6.1.5
   socks5_proxy: ^2.1.1
   socks_socket: ^0.1.0
   http: ^1.2.1
   connectivity_plus: ^6.0.3
   ```
2. `lib/services/tor/tor_service.dart` — Singleton:
   - `isTorAvailable()` → socket probe 127.0.0.1:9050
   - `verifyTorExit()` → GET via SOCKS to check.torproject.org
   - `enforceProxy()` → set ProxyController + create TorHttpClient
   - `stream< TorStatus >` → bootstrapping / ready / failed
3. `lib/services/tor/tor_http_client.dart` — Factory that always returns SOCKS client; direct client creation blocked
4. `lib/screens/tor_gate_screen.dart` — Blocking screen if Tor not ready: shows Orbot install/start buttons via intents:
   - `intent: org.torproject.android.intent.action.START`
   - Play Store link: `market://details?id=org.torproject.android`
5. `main.dart` → before `runApp()`: `await TorService.instance.enforceOrBlock()`
6. `browser_screen.dart` + `ensemble` WebViews → all use `ProxyController.instance().setProxyOverride(settings: ProxySettings(proxyRules: [ProxyRule(url: "socks://127.0.0.1:9050")]))`
7. No fallback: if `setProxyOverride` fails or port unreachable → show error, never clear to direct.

## 5. Security Hardening (Mandatory Mode)

- [ ] `android:usesCleartextTraffic="false"` in AndroidManifest
- [ ] WebView: `cacheMode: LOAD_NO_CACHE`, clearCache on Tor circuit change
- [ ] Cookies: `CookieManager.deleteAllCookies()` on app exit if user enables "Forget on close"
- [ ] DNS: use `socks5h://` semantics (Tor does remote DNS; we avoid local resolver leak)
- [ ] ControlPort isolation: enable `IsolateDestAddr` via Orbot torrc custom if user wants per-provider circuit
- [ ] Fail-closed test: Airplane mode + Orbot stopped → app shows gate, no request leaves device (verify via `adb logcat` + Wireshark)

## 6. iOS Limitation — Honest Note

- `ProxyController` is **Android only** (AndroidX WebKit). iOS WebView ki per-app SOCKS proxy set cheyadam OS support cheyyadu.
- So "Tor mandatory" V1 = **Android only**. iOS lo either:
  - Show "Tor requires Android + Orbot" message, or
  - Use Onion Browser style approach (not in scope).
- Documents lo clear ga mention chestham.

## 7. Alternative — Embedded Tor (V2, if you insist no Orbot dependency)

- Package: `flutter_tor` (Arti) → `await Tor.start(port: 9050)` → same SOCKS port
- Pros: User Orbot install cheyyalsina avasaram ledu
- Cons: APK +15 MB, bootstrap slow, battery high, Arti young — production failures
- Decision: V1 external, V2 embedded as option — user Settings lo toggle "Use embedded Tor if Orbot not found"

## 8. Play Store & Policy Notes

- Tor routing app Play Store lo allowed (Orbot itself is on Play Store with 10M installs)
- We must NOT claim "100% anonymous" — we state "Routes via Tor network; exit node still sees destination"
- No need for VPN permission if using proxy mode (only SOCKS); VPN mode ante `android.permission.BIND_VPN_SERVICE` kavali — we avoid for V1

## Sources

- Orbot SOCKS 9050 / HTTP 8118 [2](https://guardianproject.info/archive/onionkit/)
- Orbot setup SOCKS5 127.0.0.1:9050 [3](https://proxied.com/blog/using-orbot-to-socks5-tunnel-any-app-on-your-phone)
- Orbot official repo [4](https://github.com/guardianproject/orbot-android)
- webview_flutter no proxy, flutter_inappwebview ProxyController only solution [1](https://github.com/Sis-touche/Mobile_avec_tor)
- ProxyController Android-only API [2](https://inappwebview.dev/docs/webview/proxy-controller/)
- Dart ignores system proxy, needs SOCKS package [24](https://blog.snoopbees.com/why-your-proxy-doesnt-work-on-flutter-apps-and-how-to-fix-it-bba9d7c9b3f2)
- socks5_proxy usage [1](https://pub.dev/packages/socks5_proxy) [18](https://flutterawesome.com/a-dart-package-http-socks4-socks5-proxy/)
- socks_socket for Tor [4](https://github.com/cypherstack/socks_socket)
