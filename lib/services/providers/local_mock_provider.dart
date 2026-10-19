import 'package:intl/intl.dart';

import '../../models/chat_turn.dart';
import '../../models/provider_result.dart';
import 'ai_provider.dart';

/// Offline fallback. Only used when no remote model answered; the
/// orchestrator drops it whenever a real answer exists.
class LocalMockProvider extends AiProvider {
  const LocalMockProvider();

  static const String providerId = 'local-mock';

  @override
  String get id => providerId;

  @override
  String get label => 'Jarvis Local';

  @override
  String get model => 'local-fallback';

  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
  }) async {
    final sw = Stopwatch()..start();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final answer = _reply(prompt);
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

  String _reply(String input) {
    final text = input.toLowerCase();
    final now = DateTime.now();
    bool hasAny(List<String> words) => words.any(text.contains);

    if (hasAny(<String>['hello', 'hi', 'hey', 'namaste'])) {
      return 'Hello! I\'m Jarvis. The free AI models did not answer just now, so this is an offline reply. What would you like to do?';
    }
    if (hasAny(<String>['who are you', 'your name', 'jarvis'])) {
      return 'I am Jarvis, MDK Tech\'s AI assistant. Right now the free AI models are not answering, so I am in offline fallback mode.';
    }
    if (hasAny(<String>['whatsapp'])) {
      return 'For WhatsApp automation:\n1) Connect WhatsApp Business API\n2) Save FAQ answers\n3) Auto-reply + human handover\nThe Automation tab shows the planned tools (demo only for now).';
    }
    if (hasAny(<String>['flutter', 'dart', 'coding'])) {
      return 'Flutter fast-track:\n1) Dart basics\n2) Widgets (Stateless/Stateful)\n3) Layouts (Row/Column/ListView)\n4) Provider state\n5) One mini-project per week.';
    }
    if (hasAny(<String>['study', 'learn', 'exam', 'plan'])) {
      return '2-hour plan:\n• 25 min learn → 5 min break (x3)\n• 20 min practice\n• 10 min revise doubts\nTell me the subject for specifics.';
    }
    if (hasAny(<String>['time'])) {
      return 'It\'s ${DateFormat('hh:mm a').format(now)}.';
    }
    if (hasAny(<String>['date', 'today'])) {
      return 'Today is ${DateFormat('EEEE, d MMMM yyyy').format(now)}.';
    }
    return 'The free AI models did not answer this time, so this is an offline reply to: "$input". Check Orbot and your connection, then try again.';
  }
}
