import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';

const String kJarvisSystemPrompt =
    'You are Jarvis, a helpful AI assistant from MDK Tech. Be concise, '
    'friendly and accurate. Use the conversation so far for context.';

/// Shared OpenAI-compatible chat-completions call used by every remote provider.
/// Never throws. Error messages never include the response body (it may echo
/// the prompt or contain account details).
Future<ProviderResult> postChatCompletion({
  required http.Client client,
  required Uri uri,
  required String providerId,
  required String label,
  required String model,
  required String prompt,
  List<ChatTurn> history = const <ChatTurn>[],
  String? apiKey,
  int maxTokens = 700,
  Duration timeout = const Duration(seconds: 25),
}) async {
  final sw = Stopwatch()..start();

  ProviderResult fail(String message) => ProviderResult.error(
        providerId: providerId,
        providerLabel: label,
        model: model,
        error: message,
      );

  try {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final key = apiKey?.trim() ?? '';
    if (key.isNotEmpty) headers['Authorization'] = 'Bearer $key';

    final body = jsonEncode(<String, dynamic>{
      'model': model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': kJarvisSystemPrompt},
        for (final ChatTurn t in history) t.toJson(),
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': maxTokens,
    });

    final resp =
        await client.post(uri, headers: headers, body: body).timeout(timeout);
    sw.stop();

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      return fail('HTTP ${resp.statusCode}');
    }
    final content = _extractContent(resp.body);
    if (content == null || content.isEmpty) return fail('Empty answer');

    return ProviderResult(
      providerId: providerId,
      providerLabel: label,
      model: model,
      answer: content,
      status: ProviderStatus.success,
      latencyMs: sw.elapsedMilliseconds,
    );
  } on TimeoutException {
    return ProviderResult.timeout(
      providerId: providerId,
      providerLabel: label,
      model: model,
    );
  } catch (_) {
    return fail('Request failed');
  }
}

String? _extractContent(String raw) {
  final data = jsonDecode(raw);
  if (data is! Map) return null;
  final choices = data['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final first = choices.first;
  if (first is! Map) return null;
  final message = first['message'];
  if (message is! Map) return null;
  final content = message['content'];
  return content is String ? content.trim() : null;
}
