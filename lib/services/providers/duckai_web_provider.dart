import 'dart:async';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/constants/app_constants.dart';
import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';
import '../tor/tor_service.dart';
import '../tor/tor_webview.dart';
import 'ai_provider.dart';

/// EXPERIMENTAL. Sends the prompt to the duck.ai web page in a hidden,
/// Tor-proxied WebView and reads the reply back with JavaScript.
///
/// Caveats (read before enabling):
/// * The CSS selectors below are best guesses. Duck.ai can change its page at
///   any time, and this has not been verified on a device.
/// * Driving a web UI may conflict with the site's terms of use. It is off by
///   default and only runs when the user turns it on in Settings.
/// * Duck.ai has no memory API here, so only the new question is sent.
class DuckAiProvider extends AiProvider {
  const DuckAiProvider();

  static const Duration _deadline = Duration(seconds: 60);

  @override
  String get id => 'duckai-web';

  @override
  String get label => 'Duck.ai (web)';

  @override
  String get model => 'duck.ai';

  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
  }) async {
    final sw = Stopwatch()..start();
    ProviderResult fail(String msg) => ProviderResult.error(
          providerId: id,
          providerLabel: label,
          model: model,
          error: msg,
        );

    try {
      await TorService.instance.requireReady();
      await applyTorProxyOverride();
    } catch (e) {
      return fail(e.toString());
    }

    final done = Completer<String?>();
    var started = false;

    final headless = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(AppConstants.duckAiUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useShouldOverrideUrlLoading: false,
      ),
      onLoadStop: (InAppWebViewController controller, WebUri? url) async {
        if (started || done.isCompleted) return;
        started = true;
        // Let the page's own scripts settle before typing.
        await Future<void>.delayed(const Duration(seconds: 3));
        try {
          await controller.evaluateJavascript(source: _sendScript(prompt));
        } catch (_) {
          if (!done.isCompleted) done.complete(null);
          return;
        }
        unawaited(_poll(controller, prompt, done));
      },
    );

    try {
      await headless.run();
      final answer = await done.future.timeout(_deadline, onTimeout: () => null);
      sw.stop();
      if (answer == null || answer.trim().isEmpty) {
        return fail('No answer from duck.ai');
      }
      return ProviderResult(
        providerId: id,
        providerLabel: label,
        model: model,
        answer: answer.trim(),
        status: ProviderStatus.success,
        latencyMs: sw.elapsedMilliseconds,
      );
    } catch (_) {
      return fail('duck.ai WebView failed');
    } finally {
      if (!done.isCompleted) done.complete(null);
      await headless.dispose();
    }
  }

  /// Types the prompt into the page and clicks send. Returns true/false.
  String _sendScript(String prompt) {
    final literal = jsonEncode(prompt);
    return '''
(function () {
  var box = document.querySelector('textarea') ||
            document.querySelector('[contenteditable="true"]');
  if (!box) return false;
  if (box.tagName === 'TEXTAREA') {
    box.value = $literal;
  } else {
    box.innerText = $literal;
  }
  box.dispatchEvent(new Event('input', { bubbles: true }));
  var btn = document.querySelector('button[type="submit"]') ||
            document.querySelector('button[aria-label*="Send" i]');
  if (!btn) return false;
  btn.click();
  return true;
})();
''';
  }

  /// Reads the newest non-user message. Returns it once it is unchanged for
  /// three polls in a row (about 4.5 s), or null at the deadline.
  Future<void> _poll(
    InAppWebViewController controller,
    String prompt,
    Completer<String?> done,
  ) async {
    const readScript = '''
(function () {
  var nodes = document.querySelectorAll(
    '[data-testid*="message" i], [class*="message" i], article'
  );
  for (var i = nodes.length - 1; i >= 0; i--) {
    var t = (nodes[i].innerText || '').trim();
    if (t) return t;
  }
  return '';
})();
''';
    final endAt = DateTime.now().add(_deadline);
    var last = '';
    var stable = 0;
    while (!done.isCompleted && DateTime.now().isBefore(endAt)) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      try {
        final raw = await controller.evaluateJavascript(source: readScript);
        final text = raw is String ? raw.trim() : '';
        if (text.isNotEmpty && text != prompt.trim() && text == last) {
          stable++;
          if (stable >= 3) {
            if (!done.isCompleted) done.complete(text);
            return;
          }
        } else {
          stable = 0;
        }
        last = text;
      } catch (_) {
        if (!done.isCompleted) done.complete(null);
        return;
      }
    }
    if (!done.isCompleted) done.complete(null);
  }
}
