import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

/// State for the chat: message list + "Jarvis is typing" flag.
class ChatProvider extends ChangeNotifier {
  ChatProvider({AiService? aiService}) : _aiService = aiService ?? AiService() {
    _messages.add(ChatMessage.assistant(AppConstants.welcomeMessage));
  }

  final AiService _aiService;
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
      final reply = await _aiService.getReply(trimmed);
      _messages.add(ChatMessage.assistant(reply));
    } catch (_) {
      _messages.add(
        ChatMessage.assistant(
          'Sorry, something went wrong. Please try again.',
        ),
      );
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
    _aiService.dispose();
    super.dispose();
  }
}
