import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../services/orchestrator/judge_service.dart';
import '../services/orchestrator/multi_ai_orchestrator.dart';
import '../services/tor/tor_service.dart';

/// State for the chat: message list + "typing" flag.
/// Every question is fanned out to the ensemble (through Tor) and judged.
class ChatProvider extends ChangeNotifier {
  ChatProvider({MultiAiOrchestrator? orchestrator})
      : _orchestrator = orchestrator ?? MultiAiOrchestrator(useTor: true) {
    _messages.add(ChatMessage.assistant(AppConstants.welcomeMessage));
  }

  final MultiAiOrchestrator _orchestrator;
  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isTyping = false;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get hasOnlyWelcome => _messages.length <= 1;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _messages.add(ChatMessage.user(trimmed));
    _isTyping = true;
    notifyListeners();

    try {
      // Fail-closed: refuse to send anything if Tor is down.
      await TorService.instance.requireReady();
      final JudgedResult result = await _orchestrator.ask(trimmed);
      _messages.add(ChatMessage.assistant(result.finalAnswer));
    } on TorBlockedException {
      _messages.add(ChatMessage.assistant(
        'Tor is not running, so I can\'t send your message. '
        'Start Orbot (proxy mode) and try again.',
      ));
    } catch (_) {
      _messages.add(ChatMessage.assistant(
        'Sorry, something went wrong. Please try again.',
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages
      ..clear()
      ..add(ChatMessage.assistant(AppConstants.welcomeMessage));
    _isTyping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
