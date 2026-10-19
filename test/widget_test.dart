import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mdk_tech_ai_automation/core/constants/app_constants.dart';
import 'package:mdk_tech_ai_automation/models/chat_message.dart';
import 'package:mdk_tech_ai_automation/models/chat_turn.dart';
import 'package:mdk_tech_ai_automation/models/provider_result.dart';
import 'package:mdk_tech_ai_automation/providers/chat_provider.dart';
import 'package:mdk_tech_ai_automation/services/orchestrator/ensemble_config.dart';
import 'package:mdk_tech_ai_automation/services/orchestrator/judge_service.dart';
import 'package:mdk_tech_ai_automation/services/orchestrator/multi_ai_orchestrator.dart';
import 'package:mdk_tech_ai_automation/services/providers/ai_provider.dart';
import 'package:mdk_tech_ai_automation/services/providers/local_mock_provider.dart';
import 'package:mdk_tech_ai_automation/services/storage/chat_storage.dart';
import 'package:mdk_tech_ai_automation/services/storage/settings_provider.dart';

class _FakeProvider extends AiProvider {
  _FakeProvider(this.id, this.answer, {this.onHistory});

  final String answer;
  final void Function(int historyLength)? onHistory;

  @override
  final String id;
  @override
  String get label => 'Fake $id';
  @override
  String get model => 'fake/$id';
  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(
    String prompt, {
    List<ChatTurn> history = const <ChatTurn>[],
  }) async {
    onHistory?.call(history.length);
    return ProviderResult(
      providerId: id,
      providerLabel: label,
      model: model,
      answer: answer,
      status: ProviderStatus.success,
    );
  }
}

const EnsembleConfig _noSynth = EnsembleConfig(synthesisEnabled: false);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('app constants expose the app name and synthesis model', () {
    expect(AppConstants.appName, 'MDK Jarvis AI');
    expect(AppConstants.kiloSynthesisModel, isNotEmpty);
  });

  test('judge returns the only successful answer', () {
    final result = JudgeService().judge(<ProviderResult>[
      ProviderResult.error(
        providerId: 'a',
        providerLabel: 'A',
        model: 'm',
        error: 'boom',
      ),
      const ProviderResult(
        providerId: 'b',
        providerLabel: 'B',
        model: 'm',
        answer: 'Only good answer here, long enough to pass.',
        status: ProviderStatus.success,
      ),
    ]);
    expect(result.finalAnswer, 'Only good answer here, long enough to pass.');
  });

  test('local fallback is dropped when a real AI answered', () async {
    final orchestrator = MultiAiOrchestrator(
      config: _noSynth,
      providers: <AiProvider>[
        _FakeProvider('kilo-x', 'Real answer from a real model, detailed enough.'),
        const LocalMockProvider(),
      ],
    );
    final result = await orchestrator.ask('hello');
    expect(result.winner?.providerId, 'kilo-x');
  });

  test('local fallback answers when nothing else did', () async {
    final orchestrator = MultiAiOrchestrator(
      config: _noSynth,
      providers: <AiProvider>[const LocalMockProvider()],
    );
    final result = await orchestrator.ask('hello');
    expect(result.winner?.providerId, LocalMockProvider.providerId);
  });

  test('conversation history is passed to providers', () async {
    var seen = -1;
    final orchestrator = MultiAiOrchestrator(
      config: _noSynth,
      providers: <AiProvider>[
        _FakeProvider(
          'kilo-x',
          'An answer that is long enough to count.',
          onHistory: (int n) => seen = n,
        ),
      ],
    );
    await orchestrator.ask(
      'next question',
      history: const <ChatTurn>[
        ChatTurn(role: 'user', content: 'first'),
        ChatTurn(role: 'assistant', content: 'reply'),
      ],
    );
    expect(seen, 2);
  });

  test('chat memory skips the welcome banner', () async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await SettingsProvider.load(
      prefs: prefs,
      secrets: MemorySecretStore(),
    );
    final chat = ChatProvider(settings: settings);
    expect(chat.messages.length, 1);
    expect(chat.buildHistory(), isEmpty);
  });

  test('chat messages survive a JSON round trip with sources', () {
    final msg = ChatMessage.assistant(
      'best answer',
      sources: const <ProviderResult>[
        ProviderResult(
          providerId: 'kilo-x',
          providerLabel: 'Kilo x',
          model: 'x/x:free',
          answer: 'best answer',
          status: ProviderStatus.success,
          latencyMs: 120,
        ),
      ],
      winnerLabel: 'Kilo x',
      judgeReason: 'Best of 1',
    );
    final back = ChatMessage.fromJson(msg.toJson());
    expect(back.text, 'best answer');
    expect(back.winner?.providerId, 'kilo-x');
    expect(back.judgeReason, 'Best of 1');
  });

  test('custom endpoint is off until URL and key are both set', () {
    expect(const EnsembleConfig().hasCustom, isFalse);
    expect(
      const EnsembleConfig(
        customUrl: 'https://x/v1/chat/completions',
        customKey: 'k',
      ).hasCustom,
      isTrue,
    );
  });

  test('chat storage keeps messages across instances', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = ChatStorage(prefs);
    await storage.save(<ChatMessage>[ChatMessage.user('hi there')]);
    final loaded = ChatStorage(prefs).load();
    expect(loaded.single.text, 'hi there');
    await storage.clear();
    expect(ChatStorage(prefs).load(), isEmpty);
  });
}
