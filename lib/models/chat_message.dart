import 'provider_result.dart';

/// A single message in the chat. Assistant messages may carry the
/// per-model answers they were judged from ([sources]).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources = const <ProviderResult>[],
    this.winnerLabel,
    this.judgeReason,
  });

  factory ChatMessage.user(String text) {
    final now = DateTime.now();
    return ChatMessage(
      id: now.microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: now,
    );
  }

  factory ChatMessage.assistant(
    String text, {
    List<ProviderResult> sources = const <ProviderResult>[],
    String? winnerLabel,
    String? judgeReason,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: now.microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: now,
      sources: sources,
      winnerLabel: winnerLabel,
      judgeReason: judgeReason,
    );
  }

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ProviderResult> sources;
  final String? winnerLabel;
  final String? judgeReason;

  bool get hasSources => sources.isNotEmpty;

  /// The source whose label matches [winnerLabel], if any.
  ProviderResult? get winner {
    for (final r in sources) {
      if (r.providerLabel == winnerLabel) return r;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'sources': sources.map((ProviderResult r) => r.toJson()).toList(),
        'winnerLabel': winnerLabel,
        'judgeReason': judgeReason,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] as List<dynamic>?;
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sources: rawSources == null
          ? const <ProviderResult>[]
          : rawSources
              .map((dynamic e) =>
                  ProviderResult.fromJson(e as Map<String, dynamic>))
              .toList(),
      winnerLabel: json['winnerLabel'] as String?,
      judgeReason: json['judgeReason'] as String?,
    );
  }
}
