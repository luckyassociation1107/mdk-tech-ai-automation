import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../services/tor/tor_service.dart';
import '../services/voice/voice_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/provider_answer_sheet.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (VoiceService.instance.isListening) {
      await VoiceService.instance.stopListening();
    }
    _controller.clear();
    final chat = context.read<ChatProvider>();
    final future = chat.sendMessage(text);
    _scrollToBottom();
    await future;
    _scrollToBottom();
  }

  Future<void> _toggleMic() async {
    final voice = VoiceService.instance;
    if (voice.isListening) {
      await voice.stopListening();
      return;
    }
    final ok = await voice.startListening((String text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is not available. Check mic permission.'),
        ),
      );
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will remove all messages in this chat.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ChatProvider>().clearChat();
    }
  }

  void _showSources(ChatMessage m) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => ProviderAnswerSheet(
        winner: m.winner,
        allAnswers: m.sources,
        reason: m.judgeReason ?? '',
      ),
    );
  }

  Widget _torChip() {
    return AnimatedBuilder(
      animation: TorService.instance,
      builder: (BuildContext context, Widget? _) {
        final ok = TorService.instance.isReady;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(ok ? Icons.lock : Icons.lock_open, size: 16),
            label: Text(ok ? 'Tor' : 'No Tor', style: const TextStyle(fontSize: 12)),
            backgroundColor: ok
                ? Colors.green.withValues(alpha: 0.18)
                : Colors.orange.withValues(alpha: 0.2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: scheme.primary,
              child: Icon(Icons.smart_toy, color: scheme.onPrimary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Powered by ${AppConstants.companyName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          _torChip(),
          IconButton(
            tooltip: 'Clear chat',
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (BuildContext context, ChatProvider chat, Widget? _) {
                final itemCount = chat.messages.length + (chat.isTyping ? 1 : 0);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: itemCount,
                  itemBuilder: (BuildContext context, int i) {
                    if (chat.isTyping && i == itemCount - 1) {
                      return const TypingIndicator();
                    }
                    final ChatMessage m = chat.messages[i];
                    return MessageBubble(
                      message: m,
                      onShowSources: m.hasSources ? () => _showSources(m) : null,
                      onSpeak: m.isUser
                          ? null
                          : () => VoiceService.instance.speak(m.text),
                    );
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (BuildContext context, ChatProvider chat, Widget? _) {
              if (!chat.hasOnlyWelcome) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.suggestionPrompts
                      .map(
                        (String p) => ActionChip(
                          label: Text(p),
                          onPressed: chat.isTyping ? null : () => _send(p),
                        ),
                      )
                      .toList(),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: <Widget>[
                  AnimatedBuilder(
                    animation: VoiceService.instance,
                    builder: (BuildContext context, Widget? _) {
                      final listening = VoiceService.instance.isListening;
                      return IconButton(
                        tooltip: listening ? 'Stop listening' : 'Speak',
                        onPressed: _toggleMic,
                        icon: Icon(listening ? Icons.mic : Icons.mic_none),
                        color: listening ? scheme.error : null,
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask Jarvis anything...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder:
                        (BuildContext context, ChatProvider chat, Widget? _) {
                      return IconButton.filled(
                        tooltip: 'Send',
                        onPressed: chat.isTyping ? null : () => _send(),
                        icon: const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
