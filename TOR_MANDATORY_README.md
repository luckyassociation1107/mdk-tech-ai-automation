# 🔐 Tor Privacy MANDATORY — MDK Jarvis AI

> **Single line:** App lo prathi request Tor dwara ne vellali — direct leak ledhu, fail-closed.

## Quick Setup (User ki)

### Android (V1 — Full Tor)
1. **Orbot install cheyyi:** [Play Store](https://play.google.com/store/apps/details?id=org.torproject.android) or F-Droid
2. Orbot open → **Start** → SOCKS `127.0.0.1:9050` active avvali (Power User Mode → Proxy mode, VPN mode vaddu)
3. MDK Jarvis app open → auto Tor check → Green "Tor Ready" kanipiste done
4. Tor lekapothe app **block** avuthundi — "Start Orbot" button vasthundi, direct ga chat open avadu (privacy kosam)

### iOS / Desktop
- V1 lo Tor mandatory = **Android only**. iOS lo WebView proxy OS support cheyyadu, so warning chupistham. V2 lo embedded option add chestham.

## Developer — How It Works

| What | How |
|------|-----|
| HTTP (AI APIs) | `socks5_proxy` → `SocksTCPClient.assignToHttpClient(client, [127.0.0.1:9050])` → all via Tor |
| WebView (Duck.ai/DeepSeek etc) | `flutter_inappwebview` → `ProxyController.setProxyOverride(socks://127.0.0.1:9050)` → only package that supports per-app proxy on Android 10+ |
| Check | `socket.connect(127.0.0.1:9050)` + probe `check.torproject.org/api/ip` via Tor |
| Fail-closed | Proxy down ayithe `clearProxyOverride()` cheyyam — app gate screen lone stay, direct ki velladu |

Full design doc: [`docs/tor_privacy_mandatory.md`](docs/tor_privacy_mandatory.md) + no-login sites report: [`docs/no_login_websites_report.md`](docs/no_login_websites_report.md)

## Why Orbot (not embedded)?

- 10M+ installs, Tor 0.4.9.x, bridges built-in
- APK size peragadu, battery takkuva
- Embedded `flutter_tor` (Arti) V2 option — ippudu young, bootstrap slow

## Next: Code Push

Nenu `lib/services/tor/` + `tor_gate_screen.dart` + pubspec deps update chesi push chestha — confirm cheyyi.

