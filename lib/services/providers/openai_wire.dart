import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';

const String kJarvisSystemPrompt =
    'You are Jarvis, a helpful AI assistant from MDK Tech. Be concise, '
    'friendly and accurate. Use the conversation so far for context.';

List<Map<String, String>> _buildMessages(String prompt, List<ChatTurn> history) {
  return <Map<String, String>>[
    <String, String>{'role': 'system', 'content': kJarvisSystemPrompt},
    for (final ChatTurn t in history) t.toJson(),
    <String, String>{'role': 'user', 'content': prompt},
  ];
}

Map<String, String> _headers(String? apiKey) {
  final headers = <String, String>{'Content-Type': 'application/json'};
  final key = apiKey?.trim() ?? '';
  if (key.isNotEmpty) headers['Authorization'] = 'Bearer $key';
  return headers;
}

/// Shared OpenAI-compatible chat-completions call (non-streaming).
/// Never throws. Error messages never include the response body.
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
    final body = jsonEncode(<String, dynamic>{
      'model': model,
      'messages': _buildMessages(prompt, history),
      'temperature': 0.7,
      'max_tokens': maxTokens,
    });
    final resp = await client
        .post(uri, headers: _headers(apiKey), body: body)
        .timeout(timeout);
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

/// Streaming variant (Server-Sent Events). [onDelta] receives the text so far
/// after every chunk. Never throws.
Future<ProviderResult> streamChatCompletion({
  required http.Client client,
  required Uri uri,
  required String providerId,
  required String label,
  required String model,
  required String prompt,
  List<ChatTurn> history = const <ChatTurn>[],
  String? apiKey,
  int maxTokens = 700,
  Duration timeout = const Duration(seconds: 60),
  void Function(String textSoFar)? onDelta,
}) async {
  final sw = Stopwatch()..start();
  ProviderResult fail(String message) => ProviderResult.error(
        providerId: providerId,
        providerLabel: label,
        model: model,
        error: message,
      );

  try {
    final req = http.Request('POST', uri)
      ..headers.addAll(_headers(apiKey))
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(<String, dynamic>{
        'model': model,
        'messages': _buildMessages(prompt, history),
        'temperature': 0.7,
        'max_tokens': maxTokens,
        'stream': true,
      });

    final resp = await client.send(req).timeout(timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      await resp.stream.drain<void>();
      return fail('HTTP ${resp.statusCode}');
    }

    final buffer = StringBuffer();
    final lines = resp.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(timeout);
    await for (final String line in lines) {
      final delta = parseStreamLine(line);
      if (delta == _streamDone) break;
      if (delta != null && delta.isNotEmpty) {
        buffer.write(delta);
        onDelta?.call(buffer.toString());
      }
    }
    sw.stop();

    final text = buffer.toString().trim();
    if (text.isEmpty) return fail('Empty answer');
    return ProviderResult(
      providerId: providerId,
      providerLabel: label,
      model: model,
      answer: text,
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
    return fail('Stream failed');
  }
}

/// Sentinel returned by [parseStreamLine] when the stream is finished.
const String _streamDone = '\u0000__done__';

/// Parses one SSE line from an OpenAI-style stream.
/// Returns the text delta, `null` when the line carries no text, or the
/// done-sentinel on `data: [DONE]`. Exposed for unit tests.
String? parseStreamLine(String line) {
  if (!line.startsWith('data:')) return null;
  final payload = line.substring(5).trim();
  if (payload == '[DONE]') return _streamDone;
  if (payload.isEmpty) return null;
  final Object? data;
  try {
    data = jsonDecode(payload);
  } catch (_) {
    return null;
  }
  if (data is! Map) return null;
  final choices = data['choices'];
  if (choices is! List || choices.isEmpty) return null;
  final first = choices.first;
  if (first is! Map) return null;
  final delta = first['delta'];
  if (delta is! Map) return null;
  final content = delta['content'];
  return content is String ? content : null;
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
