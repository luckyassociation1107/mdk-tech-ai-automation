import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/constants/app_constants.dart';

/// Points every WebView in the app at Orbot's SOCKS port.
/// Throws if the platform cannot enforce the proxy (fail-closed: callers must
/// not load any page when this throws).
Future<void> applyTorProxyOverride() async {
  final supported = await WebViewFeature.isFeatureSupported(
    WebViewFeature.PROXY_OVERRIDE,
  );
  if (!supported) {
    throw const TorProxyUnsupportedException();
  }
  await ProxyController.instance().setProxyOverride(
    settings: ProxySettings(
      proxyRules: <ProxyRule>[
        ProxyRule(
          url: 'socks://${AppConstants.torSocksHost}:${AppConstants.torSocksPort}',
        ),
      ],
      bypassRules: const <String>[],
    ),
  );
}

class TorProxyUnsupportedException implements Exception {
  const TorProxyUnsupportedException();
  @override
  String toString() =>
      'This device WebView cannot enforce the Tor proxy (needs Android 10+).';
}
