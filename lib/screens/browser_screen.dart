import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../services/tor/tor_service.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  InAppWebViewController? _controller;
  String _currentUrl = AppConstants.duckAiUrl;
  String _currentPresetId = 'duck';
  bool _isLoading = false;
  double _progress = 0;
  bool _torReady = false;
  bool _proxyApplied = false;
  String? _blockReason;

  @override
  void initState() {
    super.initState();
    _initTorProxy();
  }

  /// Fail-closed: the WebView is only built after Tor is reachable AND the
  /// SOCKS proxy override is applied. Otherwise the page stays blocked.
  Future<void> _initTorProxy() async {
    final tor = TorService.instance;
    await tor.check();
    if (!tor.isReady) {
      setState(() {
        _torReady = false;
        _blockReason = 'Tor (Orbot) is not running. Browser blocked.';
      });
      return;
    }
    try {
      final supported = await WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE);
      if (!supported) {
        setState(() => _blockReason = 'This device WebView cannot enforce Tor proxy (needs Android 10+ / WebView proxy support). Browser blocked.');
        return;
      }
      await ProxyController.instance().setProxyOverride(
        settings: ProxySettings(
          proxyRules: [ProxyRule(url: 'socks://${AppConstants.torSocksHost}:${AppConstants.torSocksPort}')],
          bypassRules: const <String>[],
        ),
      );
      if (!mounted) return;
      setState(() {
        _torReady = true;
        _proxyApplied = true;
        _blockReason = null;
      });
    } catch (e) {
      setState(() => _blockReason = 'Could not enforce Tor proxy: $e. Browser blocked.');
    }
  }

  void _loadPreset(BrowserPreset p) {
    setState(() {
      _currentPresetId = p.id;
      _currentUrl = p.url;
    });
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(p.url)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browser — Tor + Manual'),
        actions: [
          IconButton(
            tooltip: 'Open in external browser',
            onPressed: () => launchUrl(Uri.parse(_currentUrl), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: _torReady ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(_torReady ? Icons.lock : Icons.lock_open, size: 16, color: _torReady ? Colors.green : Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _torReady
                        ? 'Tor: SOCKS ${AppConstants.torSocksHost}:${AppConstants.torSocksPort} (fail-closed)'
                        : 'Tor not detected — browser blocked (fail-closed). Start Orbot.',
                    style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_torReady)
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(TorService.instance.orbotPlayStoreUrl), mode: LaunchMode.externalApplication),
                    child: const Text('Get Orbot', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Preset chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: AppConstants.browserPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final p = AppConstants.browserPresets[i];
                final selected = p.id == _currentPresetId;
                return ChoiceChip(
                  selected: selected,
                  label: Text('${p.icon} ${p.label}'),
                  onSelected: (_) => _loadPreset(p),
                );
              },
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(value: _progress < 1 ? _progress : null),
          // URL bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                IconButton(onPressed: () => _controller?.goBack(), icon: const Icon(Icons.arrow_back, size: 20)),
                IconButton(onPressed: () => _controller?.goForward(), icon: const Icon(Icons.arrow_forward, size: 20)),
                IconButton(onPressed: () => _controller?.reload(), icon: const Icon(Icons.refresh, size: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_currentUrl, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !_proxyApplied
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_blockReason ?? 'Enforcing Tor proxy…', textAlign: TextAlign.center),
                    ),
                  )
                : InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_currentUrl)),
                    initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              onWebViewCreated: (c) => _controller = c,
              onLoadStart: (c, url) {
                if (url != null) setState(() => _currentUrl = url.toString());
              },
              onLoadStop: (c, url) {
                setState(() => _isLoading = false);
                if (url != null) setState(() => _currentUrl = url.toString());
              },
              onProgressChanged: (c, p) {
                setState(() {
                  _isLoading = p < 100;
                  _progress = p / 100;
                });
              },
              shouldOverrideUrlLoading: (c, action) async => NavigationActionPolicy.ALLOW,
            ),
          ),
          // Helper footer
          Container(
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'Tip: Log in to ChatGPT/Gemini/Qwen here with your own account. Chat tab already fans out to free Kilo models via Tor and judges the best answer.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
