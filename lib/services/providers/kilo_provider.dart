import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';
import '../tor/tor_http_client.dart';
import 'ai_provider.dart';
import 'openai_wire.dart';

/// One Kilo Gateway model = one provider. Keyless for free models.
/// All traffic goes through the Tor SOCKS client.
class KiloProvider extends AiProvider {
  KiloProvider({required this.kiloModel, http.Client? client})
      : _client = client ?? TorHttpClient.create(),
        _ownsClient = client == null;

  final String kiloModel;
  final http.Client _client;
  final bool _ownsClient;

  @override
  String get id => 'kilo-${kiloModel.replaceAll(RegExp(r'[^a-z0-9]'), '-')}';

  @override
  String get label => 'Kilo ${kiloModel.split('/').last.split(':').first}';

  @override
  String get model => kiloModel;

  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
  }) {
    return postChatCompletion(
      client: _client,
      uri: Uri.parse('${AppConstants.kiloGatewayUrl}/chat/completions'),
      providerId: id,
      label: label,
      model: kiloModel,
      prompt: prompt,
      history: history,
      apiKey: AppConstants.kiloApiKey,
    );
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
