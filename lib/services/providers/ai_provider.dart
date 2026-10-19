import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';

/// Interface every AI source implements. The orchestrator fans out to all
/// enabled providers in parallel.
abstract class AiProvider {
  const AiProvider();

  String get id;
  String get label;
  String get model;
  bool get isAvailable;

  /// Answer [prompt]. [history] is the earlier conversation (not including
  /// [prompt]). Must never throw: return a ProviderResult.error/timeout instead.
  Future<ProviderResult> getAnswer(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
  });

  /// Release any HTTP client the provider owns.
  void dispose() {}
}
