import '../../models/provider_result.dart';
import 'ai_provider.dart';

/// Duck.ai WebView provider.
/// Real WebView automation (JS injection) happens in BrowserScreen/WebView.
/// For headless/orchestrator use, this provider acts as a placeholder that
/// returns a helpful note and is *not* counted as success — so judge ignores it
/// unless the WebView layer feeds a real answer via `submitWebViewAnswer`.
///
/// This keeps the orchestrator stable even when WebView not yet wired,
/// and lets us upgrade to true JS extraction without changing orchestrator.
class DuckAiProvider implements AiProvider {
  DuckAiProvider();

  String? _lastWebViewAnswer;
  int _lastLatency = 0;

  /// Called by BrowserScreen when WebView JS extracts a real Duck.ai answer.
  void submitWebViewAnswer(String answer, {int latencyMs = 0}) {
    _lastWebViewAnswer = answer;
    _lastLatency = latencyMs;
  }

  @override
  String get id => 'duckai';

  @override
  String get label => 'Duck.ai';

  @override
  String get model => 'duck.ai/auto';

  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(String prompt) async {
    // If WebView recently supplied an answer (within this chat turn), use it.
    if (_lastWebViewAnswer != null && _lastWebViewAnswer!.trim().isNotEmpty) {
      final ans = _lastWebViewAnswer!;
      _lastWebViewAnswer = null; // consume once
      return ProviderResult(
        providerId: id,
        providerLabel: label,
        model: model,
        answer: ans,
        status: ProviderStatus.success,
        latencyMs: _lastLatency,
      );
    }

    // No WebView answer yet — return skipped so judge doesn't wait.
    // The orchestrator will still have Kilo + Local answers.
    return ProviderResult(
      providerId: id,
      providerLabel: label,
      model: model,
      answer: '',
      status: ProviderStatus.skipped,
      errorMessage: 'WebView not yet used — open Browser tab for Duck.ai',
    );
  }
}
