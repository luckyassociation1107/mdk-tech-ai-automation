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

  final String providerId; // e.g. 'kilo-glm-5-free'
  final String providerLabel; // e.g. 'Kilo glm-5'
  final String model; // e.g. 'z-ai/glm-5:free'
  final String answer;
  final ProviderStatus status;
  final int latencyMs;
  final String? errorMessage;

  bool get isSuccess =>
      status == ProviderStatus.success && answer.trim().isNotEmpty;

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'providerId': providerId,
        'providerLabel': providerLabel,
        'model': model,
        'answer': answer,
        'status': status.name,
        'latencyMs': latencyMs,
        'errorMessage': errorMessage,
      };

  factory ProviderResult.fromJson(Map<String, dynamic> json) {
    return ProviderResult(
      providerId: json['providerId'] as String,
      providerLabel: json['providerLabel'] as String,
      model: json['model'] as String,
      answer: (json['answer'] as String?) ?? '',
      status: ProviderStatus.values.byName(json['status'] as String),
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
