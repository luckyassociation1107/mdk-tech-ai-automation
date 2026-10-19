import '../../models/provider_result.dart';

/// Interface every AI source must implement.
/// Used by MultiAiOrchestrator to fan-out in parallel.
abstract class AiProvider {
  String get id; // e.g. 'kilo-glm'
  String get label; // e.g. 'Kilo GLM-4.5'
  String get model; // e.g. 'z-ai/glm-4.5:free'
  bool get isAvailable; // e.g. false if no API key / no WebView

  /// Get answer for [prompt]. Must timeout internally and return ProviderResult.error/timeout on failure.
  Future<ProviderResult> getAnswer(String prompt);
}
