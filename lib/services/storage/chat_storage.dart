import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_message.dart';

/// Saves chat history locally (last [maxMessages] messages).
/// No secrets here; history never leaves the device.
class ChatStorage {
  ChatStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'chat_history_v1';
  static const int maxMessages = 200;

  List<ChatMessage> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <ChatMessage>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <ChatMessage>[];
    }
  }

  Future<void> save(List<ChatMessage> messages) {
    final slice = messages.length > maxMessages
        ? messages.sublist(messages.length - maxMessages)
        : messages;
    return _prefs.setString(
      _key,
      jsonEncode(slice.map((ChatMessage m) => m.toJson()).toList()),
    );
  }

  Future<void> clear() => _prefs.remove(_key);
}
