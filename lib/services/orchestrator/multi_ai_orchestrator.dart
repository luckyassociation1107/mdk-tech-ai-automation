import 'dart:async';

import '../../core/constants/app_constants.dart';
import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';
import '../providers/ai_provider.dart';
import '../providers/duckai_web_provider.dart';
import '../providers/kilo_provider.dart';
import '../providers/local_mock_provider.dart';
import '../providers/openai_compat_provider.dart';
import 'ensemble_config.dart';
import 'judge_service.dart';

/// Fans a question out to every enabled model in parallel, judges the answers,
/// and optionally asks one more free model to synthesize the best final answer.
/// The synthesis is streamed: [onPartial] gets the text as it arrives.
class MultiAiOrchestrator {
  MultiAiOrchestrator({
    required this.config,
    List<AiProvider>? providers,
    JudgeService? judge,
  })  : _providersOverride = providers,
        _judge = judge ?? JudgeService();

  final EnsembleConfig config;
  final List<AiProvider>? _providersOverride;
  final JudgeService _judge;

  static const Duration _perModelTimeout = Duration(seconds: 30);
  static const Duration _webModelTimeout = Duration(seconds: 70);

  List<AiProvider> buildProviders() {
    final override = _providersOverride;
    if (override != null) return override;
    return <AiProvider>[
      for (final String m in config.kiloModels) KiloProvider(kiloModel: m),
      if (config.duckAiEnabled) const DuckAiProvider(),
      if (config.hasCustom)
        OpenAICompatProvider(
          url: config.customUrl,
          apiKey: config.customKey,
          customModel: config.customModel,
        ),
      const LocalMockProvider(),
    ];
  }

  Future<JudgedResult> ask(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
    void Function(String textSoFar)? onPartial,
  }) async {
    final providers = buildProviders();
    if (providers.isEmpty) {
      return const JudgedResult(
        finalAnswer:
            'No AI models are enabled. Turn on at least one in Settings.',
        winner: null,
        allAnswers: <ProviderResult>[],
        reason: 'No providers enabled',
      );
    }

    try {
      final results = await Future.wait(
        providers.map((AiProvider p) => _safeAnswer(p, prompt, history)),
      );

      final real = results
          .where((ProviderResult r) =>
              r.isSuccess && r.providerId != LocalMockProvider.providerId)
          .toList();

      if (real.isEmpty) return _judge.judge(results);

      final judged = _judge.judge(real);
      final base = judged.winner?.providerLabel ?? '-';

      if (!config.synthesisEnabled || real.length < 2) {
        return JudgedResult(
          finalAnswer: judged.finalAnswer,
          winner: judged.winner,
          allAnswers: results,
          reason: judged.reason,
        );
      }

      final synthesized = await _synthesize(prompt, real, onPartial);
      if (synthesized == null) {
        return JudgedResult(
          finalAnswer: judged.finalAnswer,
          winner: judged.winner,
          allAnswers: results,
          reason: '${judged.reason} (synthesis unavailable)',
        );
      }
      return JudgedResult(
        finalAnswer: synthesized,
        winner: judged.winner,
        allAnswers: results,
        reason: 'Synthesized from ${real.length} answers • base: $base',
      );
    } finally {
      for (final AiProvider p in providers) {
        p.dispose();
      }
    }
  }

  Future<ProviderResult> _safeAnswer(
    AiProvider p,
    String prompt,
    List<ChatTurn> history,
  ) async {
    final limit = p is DuckAiProvider ? _webModelTimeout : _perModelTimeout;
    try {
      return await p.getAnswer(prompt, history: history).timeout(limit);
    } on TimeoutException {
      return ProviderResult.timeout(
        providerId: p.id,
        providerLabel: p.label,
        model: p.model,
      );
    } catch (_) {
      return ProviderResult.error(
        providerId: p.id,
        providerLabel: p.label,
        model: p.model,
        error: 'Failed',
      );
    }
  }

  Future<String?> _synthesize(
    String question,
    List<ProviderResult> answers,
    void Function(String textSoFar)? onPartial,
  ) async {
    final synth = KiloProvider(kiloModel: AppConstants.kiloSynthesisModel);
    try {
      final res = await synth.streamAnswer(
        JudgeService.buildSynthesisPrompt(question, answers),
        onDelta: onPartial,
      );
      return res.isSuccess ? res.answer : null;
    } catch (_) {
      return null;
    } finally {
      synth.dispose();
    }
  }
}
