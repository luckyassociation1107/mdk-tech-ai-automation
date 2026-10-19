import 'package:http/http.dart' as http;

import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';
import '../tor/tor_http_client.dart';
import 'ai_provider.dart';
import 'openai_wire.dart';

/// User-configured OpenAI-compatible endpoint (URL + key + model from
/// Settings or --dart-define). Routed through Tor like everything else.
class OpenAICompatProvider extends AiProvider {
  OpenAICompatProvider({
    required this.url,
    required this.apiKey,
    required this.customModel,
    http.Client? client,
  })  : _client = client ?? TorHttpClient.create(isolationKey: 'custom-ai'),
        _ownsClient = client == null;

  final String url;
  final String apiKey;
  final String customModel;
  final http.Client _client;
  final bool _ownsClient;

  @override
  String get id => 'custom-ai';

  @override
  String get label => 'Custom AI';

  @override
  String get model => customModel;

  @override
  bool get isAvailable => url.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  @override
  Future<ProviderResult> getAnswer(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
  }) {
    return postChatCompletion(
      client: _client,
      uri: Uri.parse(url.trim()),
      providerId: id,
      label: label,
      model: customModel,
      prompt: prompt,
      history: history,
      apiKey: apiKey,
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
