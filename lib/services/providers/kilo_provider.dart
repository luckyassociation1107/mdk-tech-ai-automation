import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../models/provider_result.dart';
import '../tor/tor_http_client.dart';
import 'ai_provider.dart';

/// One Kilo Gateway model = one provider.
/// Free tier: 200 req/hour/IP anonymous, 40+ free models, zero-markup.
/// Base: https://api.kilo.ai/api/gateway  (OpenAI-compatible)
class KiloProvider implements AiProvider {
  KiloProvider({
    required this.kiloModel,
    http.Client? client,
    this.useTor = true,
  }) : _client = client ?? TorHttpClient.create();

  final String kiloModel;
  final http.Client _client;
  final bool useTor;

  @override
  String get id => 'kilo-${kiloModel.replaceAll(RegExp(r'[^a-z0-9]'), '-')}';

  @override
  String get label {
    // Pretty label from model id
    final short = kiloModel.split('/').last.split(':').first;
    return 'Kilo $short';
  }

  @override
  String get model => kiloModel;

  @override
  bool get isAvailable => true; // anonymous free tier always available

  @override
  Future<ProviderResult> getAnswer(String prompt) async {
    final sw = Stopwatch()..start();
    try {
      final uri = Uri.parse('${AppConstants.kiloGatewayUrl}/chat/completions');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (AppConstants.kiloApiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${AppConstants.kiloApiKey}';
      }
      // If API key empty, Kilo still serves free models anonymously (no header)

      final resp = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(<String, dynamic>{
              'model': kiloModel,
              'messages': <Map<String, String>>[
                <String, String>{
                  'role': 'system',
                  'content': 'You are Jarvis, a helpful AI from MDK Tech. Be concise, friendly, accurate.',
                },
                <String, String>{'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 600,
            }),
          )
          .timeout(const Duration(seconds: 25));

      sw.stop();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return ProviderResult.error(
          providerId: id,
          providerLabel: label,
          model: model,
          error: 'Kilo ${resp.statusCode}: ${resp.body.substring(0, resp.body.length.clamp(0, 200))}',
        );
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return ProviderResult.error(
          providerId: id,
          providerLabel: label,
          model: model,
          error: 'Empty choices',
        );
      }
      final msg = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = msg?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return ProviderResult.error(
          providerId: id,
          providerLabel: label,
          model: model,
          error: 'Empty content',
        );
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
      sw.stop();
      return ProviderResult.error(
        providerId: id,
        providerLabel: label,
        model: model,
        error: e.toString(),
      );
    }
  }

  void dispose() => _client.close();
}
