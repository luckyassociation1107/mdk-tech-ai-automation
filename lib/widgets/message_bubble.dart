import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';

/// A single chat bubble — right aligned for the user, left for Jarvis.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onShowSources,
    this.onSpeak,
  });

  final ChatMessage message;

  /// Opens the per-model answers sheet. Shown only when the message has sources.
  final VoidCallback? onShowSources;

  /// Reads the message aloud. Shown only for assistant messages.
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final labelSmall = Theme.of(context).textTheme.labelSmall;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Jarvis',
                  style: labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            SelectableText(message.text),
            if (!isUser && message.hasSources && onShowSources != null)
              InkWell(
                onTap: onShowSources,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.hub_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Sources • ${message.sources.length} models'
                          '${message.winnerLabel != null ? ' • best: ${message.winnerLabel}' : ''}',
                          style: labelSmall?.copyWith(color: scheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                if (!isUser && onSpeak != null)
                  InkWell(
                    onTap: onSpeak,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.volume_up_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
