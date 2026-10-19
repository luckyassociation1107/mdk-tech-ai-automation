enum ProviderStatus { success, timeout, error, skipped }

class ProviderResult {
  const ProviderResult({
    required this.providerId,
    required this.providerLabel,
    required this.model,
    required this.answer,
    required this.status,
    this.latencyMs = 0,
    this.errorMessage,
  });

  final String providerId; // e.g. 'kilo-glm', 'duckai', 'local'
  final String providerLabel; // e.g. 'Kilo GLM-4.5'
  final String model; // e.g. 'z-ai/glm-4.5:free'
  final String answer;
  final ProviderStatus status;
  final int latencyMs;
  final String? errorMessage;

  bool get isSuccess => status == ProviderStatus.success && answer.trim().isNotEmpty;

  factory ProviderResult.error({
    required String providerId,
    required String providerLabel,
    required String model,
    required String error,
  }) {
    return ProviderResult(
      providerId: providerId,
      providerLabel: providerLabel,
      model: model,
      answer: '',
      status: ProviderStatus.error,
      errorMessage: error,
    );
  }

  factory ProviderResult.timeout({
    required String providerId,
    required String providerLabel,
    required String model,
  }) {
    return ProviderResult(
      providerId: providerId,
      providerLabel: providerLabel,
      model: model,
      answer: '',
      status: ProviderStatus.timeout,
      errorMessage: 'Timed out',
    );
  }
}
