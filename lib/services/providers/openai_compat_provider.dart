import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../models/provider_result.dart';
import '../tor/tor_http_client.dart';
import 'ai_provider.dart';

/// Generic OpenAI-compatible provider (for custom AI_API_URL).
/// Used when user supplies AI_API_KEY + AI_API_URL via --dart-define or Settings.
class OpenAICompatProvider implements AiProvider {
  OpenAICompatProvider({http.Client? client, this.useTor = true})
      : _client = client ?? TorHttpClient.create();

  final http.Client _client;
  final bool useTor;

  @override
  String get id => 'openai-compat';

  @override
  String get label => 'Custom AI';

  @override
  String get model => AppConstants.aiModel;

  @override
  bool get isAvailable => AppConstants.aiApiKey.isNotEmpty;

  @override
  Future<ProviderResult> getAnswer(String prompt) async {
    final sw = Stopwatch()..start();
    try {
      final resp = await _client
          .post(
            Uri.parse(AppConstants.aiApiUrl),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppConstants.aiApiKey}',
            },
            body: jsonEncode(<String, dynamic>{
              'model': AppConstants.aiModel,
              'messages': <Map<String, String>>[
                <String, String>{
                  'role': 'system',
                  'content': 'You are Jarvis, a helpful AI from MDK Tech.',
                },
                <String, String>{'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 25));
      sw.stop();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return ProviderResult.error(
          providerId: id,
          providerLabel: label,
          model: model,
          error: 'API ${resp.statusCode}',
        );
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      final content = ((choices?.first as Map<String, dynamic>?)?['message'] as Map<String, dynamic>?)?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return ProviderResult.error(providerId: id, providerLabel: label, model: model, error: 'Empty');
      }
      return ProviderResult(
        providerId: id,
        providerLabel: label,
        model: model,
        answer: content.trim(),
        status: ProviderStatus.success,
        latencyMs: sw.elapsedMilliseconds,
      );
    } on TimeoutException {
      return ProviderResult.timeout(providerId: id, providerLabel: label, model: model);
    } catch (e) {
      return ProviderResult.error(providerId: id, providerLabel: label, model: model, error: e.toString());
    }
  }
}
