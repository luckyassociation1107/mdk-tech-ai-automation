/// One turn of conversation history sent to a model (OpenAI chat format).
class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  /// 'user' or 'assistant'.
  final String role;
  final String content;

  Map<String, String> toJson() => <String, String>{
        'role': role,
        'content': content,
      };
}
