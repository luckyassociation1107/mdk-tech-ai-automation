import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../orchestrator/ensemble_config.dart';

/// Storage for secrets (custom API key). Secure storage on device; in-memory in tests.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}

/// Persisted ensemble settings. Non-secret values go to SharedPreferences;
/// the custom API key goes to [SecretStore].
class SettingsProvider extends ChangeNotifier {
  SettingsProvider._(this._prefs, this._secrets, this._config);

  static const String _kKiloModels = 'kilo_models';
  static const String _kSynthesis = 'synthesis_enabled';
  static const String _kDuckAi = 'duck_ai_enabled';
  static const String _kCustomUrl = 'custom_url';
  static const String _kCustomModel = 'custom_model';
  static const String _kCustomKey = 'custom_key';

  final SharedPreferences _prefs;
  final SecretStore _secrets;
  EnsembleConfig _config;

  static Future<SettingsProvider> load({
    required SharedPreferences prefs,
    SecretStore? secrets,
  }) async {
    final store = secrets ?? const SecureSecretStore();
    final kilo = prefs.getStringList(_kKiloModels) ?? AppConstants.kiloFreeModels;
    final key = await store.read(_kCustomKey) ?? AppConstants.aiApiKey;
    return SettingsProvider._(
      prefs,
      store,
      EnsembleConfig(
        kiloModels: kilo,
        synthesisEnabled: prefs.getBool(_kSynthesis) ?? true,
        duckAiEnabled: prefs.getBool(_kDuckAi) ?? false,
        customUrl: prefs.getString(_kCustomUrl) ?? AppConstants.aiApiUrl,
        customModel: prefs.getString(_kCustomModel) ?? AppConstants.aiModel,
        customKey: key,
      ),
    );
  }

  EnsembleConfig get config => _config;

  Future<void> setKiloModelEnabled(String model, bool enabled) async {
    final list = AppConstants.kiloFreeModels
        .where((String m) => m == model ? enabled : _config.kiloModels.contains(m))
        .toList();
    _config = _config.copyWith(kiloModels: list);
    await _prefs.setStringList(_kKiloModels, list);
    notifyListeners();
  }

  Future<void> setSynthesisEnabled(bool value) async {
    _config = _config.copyWith(synthesisEnabled: value);
    await _prefs.setBool(_kSynthesis, value);
    notifyListeners();
  }

  Future<void> setDuckAiEnabled(bool value) async {
    _config = _config.copyWith(duckAiEnabled: value);
    await _prefs.setBool(_kDuckAi, value);
    notifyListeners();
  }

  /// Saves the custom endpoint. Pass empty strings to clear it.
  Future<void> saveCustom({
    required String url,
    required String model,
    required String key,
  }) async {
    _config = _config.copyWith(
      customUrl: url.trim(),
      customModel: model.trim(),
      customKey: key.trim(),
    );
    await _prefs.setString(_kCustomUrl, _config.customUrl);
    await _prefs.setString(_kCustomModel, _config.customModel);
    await _secrets.write(_kCustomKey, _config.customKey);
    notifyListeners();
  }
}
