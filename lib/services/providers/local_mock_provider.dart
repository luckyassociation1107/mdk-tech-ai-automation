import 'package:intl/intl.dart';

import '../../models/provider_result.dart';
import 'ai_provider.dart';

class LocalMockProvider implements AiProvider {
  @override
  String get id => 'local-mock';
  @override
  String get label => 'Jarvis Local';
  @override
  String get model => 'local-mock-v1';

  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(String prompt) async {
    final sw = Stopwatch()..start();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final answer = _mockReply(prompt);
    sw.stop();
    return ProviderResult(
      providerId: id,
      providerLabel: label,
      model: model,
      answer: answer,
      status: ProviderStatus.success,
      latencyMs: sw.elapsedMilliseconds,
    );
  }

  String _mockReply(String input) {
    final text = input.toLowerCase();
    final now = DateTime.now();
    bool hasAny(List<String> words) => words.any(text.contains);

    if (hasAny(<String>['hello', 'hi', 'hey', 'namaste'])) {
      return 'Hello! I\'m Jarvis (local mode). I can help with automations, Flutter, study plans, coding. What shall we do first?';
    }
    if (hasAny(<String>['who are you', 'your name', 'jarvis'])) {
      return 'I am Jarvis — MDK Tech\'s AI assistant. Running in local demo mode. Enable Kilo/Duck.ai providers in Settings for multi-AI answers.';
    }
    if (hasAny(<String>['whatsapp'])) {
      return 'For WhatsApp automation:\n1) Connect WhatsApp Business API\n2) Save FAQ answers\n3) Auto-reply + human handover\nToggle it in Automation tab.';
    }
    if (hasAny(<String>['automat'])) {
      return 'I automate WhatsApp, Email, Social posts, Reminders, Lead follow-ups, Study plans. Open Automation tab and switch on what you need.';
    }
    if (hasAny(<String>['flutter', 'dart', 'code', 'coding', 'app'])) {
      return 'Flutter fast-track:\n1) Dart basics\n2) Widgets (Stateless/Stateful)\n3) Layouts (Row/Column/ListView)\n4) Provider state\n5) One mini-project/week. Want a day-by-day plan?';
    }
    if (hasAny(<String>['study', 'learn', 'exam', 'plan'])) {
      return '2-hour plan:\n• 25m learn → 5m break (x3)\n• 20m practice\n• 10m revise doubts\nTell subject for specifics.';
    }
    if (hasAny(<String>['time'])) {
      return 'It\'s ${DateFormat('hh:mm a').format(now)}.';
    }
    if (hasAny(<String>['date', 'today'])) {
      return 'Today is ${DateFormat('EEEE, d MMMM yyyy').format(now)}.';
    }
    if (hasAny(<String>['help'])) {
      return 'Try:\n• "What automation can you do?"\n• "Help me learn Flutter"\n• "Compare AIs: explain quantum computing"';
    }
    return 'You said: "$input".\n\nLocal mock — enable Kilo Gateway free models in Settings for full AI answers (no login needed).';
  }
}
