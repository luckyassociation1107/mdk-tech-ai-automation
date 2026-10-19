import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/chat_turn.dart';
import '../models/provider_result.dart';
import '../services/orchestrator/ensemble_config.dart';
import '../services/orchestrator/multi_ai_orchestrator.dart';
import '../services/storage/chat_storage.dart';
import '../services/storage/settings_provider.dart';
import '../services/tor/tor_service.dart';

/// Chat state: messages, typing flag, conversation memory, streaming, persistence.
/// Every question is fanned out to the enabled models through Tor and judged.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required this.settings,
    this.storage,
    List<ChatMessage>? initial,
    MultiAiOrchestrator Function(EnsembleConfig config)? orchestratorFactory,
  }) : _factory = orchestratorFactory ??
            ((EnsembleConfig cfg) => MultiAiOrchestrator(config: cfg)) {
    _messages.addAll(initial ?? const <ChatMessage>[]);
    if (_messages.isEmpty) {
      _messages.add(ChatMessage.assistant(AppConstants.welcomeMessage));
    }
  }

  final SettingsProvider settings;
  final ChatStorage? storage;
  final MultiAiOrchestrator Function(EnsembleConfig config) _factory;

  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isTyping = false;

  /// Index of the assistant message currently being streamed, if any.
  int? _streamIndex;

  /// How much earlier conversation is sent with each question.
  static const int historyTurns = 6;
  static const int historyCharsPerTurn = 1200;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get hasOnlyWelcome => _messages.length <= 1;

  /// Recent turns (without the welcome banner) to send as memory.
  List<ChatTurn> buildHistory() {
    final turns = <ChatTurn>[];
    for (final ChatMessage m in _messages) {
      if (!m.isUser && m.text == AppConstants.welcomeMessage) continue;
      if (m.text.trim().isEmpty) continue;
      final content = m.text.length > historyCharsPerTurn
          ? m.text.substring(0, historyCharsPerTurn)
          : m.text;
      turns.add(ChatTurn(role: m.isUser ? 'user' : 'assistant', content: content));
    }
    return turns.length > historyTurns
        ? turns.sublist(turns.length - historyTurns)
        : turns;
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    final history = buildHistory();
    _messages.add(ChatMessage.user(trimmed));
    _isTyping = true;
    _streamIndex = null;
    notifyListeners();

    try {
      // Fail-closed: nothing is sent unless Tor is verified.
      await TorService.instance.requireReady();
      final orchestrator = _factory(settings.config);
      final result = await orchestrator.ask(
        trimmed,
        history: history,
        onPartial: _onPartial,
      );
      _finish(
        ChatMessage.assistant(
          result.finalAnswer,
          sources: result.allAnswers
              .where((ProviderResult r) => r.status != ProviderStatus.skipped)
              .toList(),
          winnerLabel: result.winner?.providerLabel,
          judgeReason: result.reason,
        ),
      );
    } on TorBlockedException {
      _finish(ChatMessage.assistant(
        'Tor is not verified, so I did not send your message. '
        'Start Orbot (proxy mode) and try again.',
      ));
    } catch (_) {
      _finish(ChatMessage.assistant(
        'Sorry, something went wrong. Please try again.',
      ));
    } finally {
      _isTyping = false;
      _streamIndex = null;
      notifyListeners();
      await _persist();
    }
  }

  /// Streamed text from the synthesis step. Creates the bubble on first call.
  void _onPartial(String partial) {
    final idx = _streamIndex;
    if (idx == null) {
      _messages.add(ChatMessage.assistant(partial));
      _streamIndex = _messages.length - 1;
    } else {
      _messages[idx] = _messages[idx].copyWith(text: partial);
    }
    notifyListeners();
  }

  /// Replaces the streamed placeholder (if any) with the final message.
  void _finish(ChatMessage finalMessage) {
    final idx = _streamIndex;
    if (idx != null) {
      _messages[idx] = finalMessage;
    } else {
      _messages.add(finalMessage);
    }
    _streamIndex = null;
  }

  Future<void> clearChat() async {
    _messages
      ..clear()
      ..add(ChatMessage.assistant(AppConstants.welcomeMessage));
    _isTyping = false;
    _streamIndex = null;
    notifyListeners();
    await storage?.clear();
  }

  Future<void> _persist() async {
    final s = storage;
    if (s != null) await s.save(List<ChatMessage>.of(_messages));
  }
}
