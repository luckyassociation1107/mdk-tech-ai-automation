import '../../core/constants/app_constants.dart';

/// What the ensemble should query. Built from Settings (persisted).
class EnsembleConfig {
  const EnsembleConfig({
    this.kiloModels = AppConstants.kiloFreeModels,
    this.synthesisEnabled = true,
    this.customUrl = '',
    this.customKey = '',
    this.customModel = '',
  });

  final List<String> kiloModels;
  final bool synthesisEnabled;
  final String customUrl;
  final String customKey;
  final String customModel;

  bool get hasCustom => customUrl.trim().isNotEmpty && customKey.trim().isNotEmpty;

  EnsembleConfig copyWith({
    List<String>? kiloModels,
    bool? synthesisEnabled,
    String? customUrl,
    String? customKey,
    String? customModel,
  }) {
    return EnsembleConfig(
      kiloModels: kiloModels ?? this.kiloModels,
      synthesisEnabled: synthesisEnabled ?? this.synthesisEnabled,
      customUrl: customUrl ?? this.customUrl,
      customKey: customKey ?? this.customKey,
      customModel: customModel ?? this.customModel,
    );
  }
}
