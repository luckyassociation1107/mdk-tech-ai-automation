import '../../core/constants/app_constants.dart';
import '../../models/provider_result.dart';
import '../providers/ai_provider.dart';
import '../providers/duckai_provider.dart';
import '../providers/kilo_provider.dart';
import '../providers/local_mock_provider.dart';
import '../providers/openai_compat_provider.dart';
import 'judge_service.dart';

/// Fans out to multiple AIs in parallel, collects with timeout, judges best.
class MultiAiOrchestrator {
  MultiAiOrchestrator({
    List<AiProvider>? providers,
    JudgeService? judge,
    this.useTor = true,
    this.enableKilo = true,
    this.enableDuckAi = true,
    this.enableCustom = true,
  })  : _judge = judge ?? JudgeService(),
        _customProviders = providers;

  final JudgeService _judge;
  final List<AiProvider>? _customProviders;
  final bool useTor;
  final bool enableKilo;
  final bool enableDuckAi;
  final bool enableCustom;

  List<AiProvider> _buildProviders() {
    if (_customProviders != null) return _customProviders;
    final list = <AiProvider>[];
    if (enableKilo) {
      for (final m in AppConstants.kiloFreeModels) {
        list.add(KiloProvider(kiloModel: m, useTor: useTor));
      }
    }
    if (enableDuckAi) {
      list.add(DuckAiProvider());
    }
    if (enableCustom && AppConstants.aiApiKey.isNotEmpty) {
      list.add(OpenAICompatProvider(useTor: useTor));
    }
    // Always keep local mock as last fallback
    list.add(LocalMockProvider());
    return list.where((p) => p.isAvailable).toList();
  }

  Future<JudgedResult> ask(String prompt) async {
    final providers = _buildProviders();
    if (providers.isEmpty) {
      return JudgedResult(
        finalAnswer: 'No AI providers available.',
        winner: null,
        allAnswers: const [],
        reason: 'No providers',
      );
    }

    final futures = providers.map((p) async {
      try {
        return await p.getAnswer(prompt).timeout(const Duration(seconds: 30));
      } catch (_) {
        return ProviderResult.timeout(providerId: p.id, providerLabel: p.label, model: p.model);
      }
    }).toList();

    final results = await Future.wait(futures);
    return _judge.judge(results);
  }

  /// For UI progress: stream results as they arrive (optional use).
  Stream<ProviderResult> askStream(String prompt) async* {
    final providers = _buildProviders();
    final completers = providers.map((p) async {
      try {
        return await p.getAnswer(prompt).timeout(const Duration(seconds: 30));
      } catch (_) {
        return ProviderResult.timeout(providerId: p.id, providerLabel: p.label, model: p.model);
      }
    }).toList();

    // Yield as each completes (unordered)
    for (final f in completers) {
      yield await f;
    }
  }
}
