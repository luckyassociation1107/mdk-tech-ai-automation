import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';

/// Talks to the AI.
///
/// * If an API key is supplied at build time
///   (`--dart-define=AI_API_KEY=...`), it calls an OpenAI-compatible
///   chat-completions endpoint.
/// * Otherwise it falls back to a built-in local "mock Jarvis" so the
///   app works fully offline / without any key for demos & development.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> getReply(String userMessage) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return 'Please type something and I\'ll help you with it.';
    }

    if (AppConstants.aiApiKey.isNotEmpty) {
      try {
        return await _getRemoteReply(trimmed);
      } catch (_) {
        // Network / API problem — fall back to local replies instead of
        // leaving the user with an error.
        return _mockReply(trimmed);
      }
    }

    // Simulate "thinking" time for a natural chat feel.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return _mockReply(trimmed);
  }

  Future<String> _getRemoteReply(String userMessage) async {
    final response = await _client.post(
      Uri.parse(AppConstants.aiApiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConstants.aiApiKey}',
      },
      body: jsonEncode(<String, dynamic>{
        'model': AppConstants.aiModel,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'system',
            'content':
                'You are Jarvis, a helpful AI assistant from MDK Tech. '
                    'Be concise, friendly and practical.',
          },
          <String, String>{'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI API returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty AI response');
    }
    final message =
        (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('Empty AI message');
    }
    return content.trim();
  }

  String _mockReply(String input) {
    final text = input.toLowerCase();
    final now = DateTime.now();

    bool hasAny(List<String> words) => words.any(text.contains);

    if (hasAny(<String>['hello', 'hi', 'hey', 'namaste'])) {
      return 'Hello! Great to see you. I can help with questions, study '
          'plans, coding, and automations. What shall we do first?';
    }
    if (hasAny(<String>['who are you', 'your name', 'jarvis'])) {
      return 'I am Jarvis — the AI assistant of MDK Tech. I\'m currently '
          'running in local demo mode. Add an AI API key (see the README) '
          'and I\'ll answer with a real AI model.';
    }
    if (hasAny(<String>['whatsapp'])) {
      return 'For WhatsApp automation:\n'
          '1) Connect the WhatsApp Business API\n'
          '2) Save answers for FAQs (price, timings, location)\n'
          '3) I auto-reply instantly and hand over to a human when needed.\n'
          'You can switch this on in the Automation tab.';
    }
    if (hasAny(<String>['automat'])) {
      return 'I can automate WhatsApp replies, emails, social media posts, '
          'task reminders, lead follow-ups and study plans. Open the '
          'Automation tab below and switch on what you need.';
    }
    if (hasAny(<String>['flutter', 'dart', 'code', 'coding', 'app'])) {
      return 'To learn Flutter fast:\n'
          '1) Dart basics (variables, functions, classes)\n'
          '2) Widgets: Stateless vs Stateful\n'
          '3) Layouts: Row, Column, ListView\n'
          '4) State management (this app uses Provider)\n'
          '5) Build one small project every week.\n'
          'Want a day-by-day plan? Just ask!';
    }
    if (hasAny(<String>['study', 'learn', 'exam', 'plan'])) {
      return 'Here\'s a simple 2-hour study plan:\n'
          '• 25 min learn → 5 min break (x3)\n'
          '• 20 min practice questions\n'
          '• 10 min revise & note doubts\n'
          'Tell me your subject and I\'ll make it specific.';
    }
    if (hasAny(<String>['time'])) {
      return 'It\'s ${DateFormat('hh:mm a').format(now)} right now.';
    }
    if (hasAny(<String>['date', 'today', 'day'])) {
      return 'Today is ${DateFormat('EEEE, d MMMM yyyy').format(now)}.';
    }
    if (hasAny(<String>['thank'])) {
      return 'You\'re welcome! Anything else I can do for you?';
    }
    if (hasAny(<String>['bye', 'goodbye'])) {
      return 'Goodbye! I\'ll be right here whenever you need me.';
    }
    if (hasAny(<String>['help'])) {
      return 'Try asking me things like:\n'
          '• "What automation can you do?"\n'
          '• "Help me learn Flutter"\n'
          '• "Give me a study plan"\n'
          '• "What\'s the time?"';
    }

    return 'That\'s interesting — you said: "$input".\n\n'
        'In local demo mode I can answer best about MDK Tech automations, '
        'Flutter/coding and study plans. Connect a real AI API key (see '
        'README) for full open-ended answers.';
  }

  void dispose() => _client.close();
}
