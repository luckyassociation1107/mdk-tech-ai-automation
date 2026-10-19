import 'package:flutter_test/flutter_test.dart';

import 'package:mdk_tech_ai_automation/core/constants/app_constants.dart';
import 'package:mdk_tech_ai_automation/models/provider_result.dart';
import 'package:mdk_tech_ai_automation/providers/chat_provider.dart';
import 'package:mdk_tech_ai_automation/services/orchestrator/judge_service.dart';
import 'package:mdk_tech_ai_automation/services/providers/ai_provider.dart';
import 'package:mdk_tech_ai_automation/services/providers/local_mock_provider.dart';
import 'package:mdk_tech_ai_automation/services/orchestrator/multi_ai_orchestrator.dart';

class _FakeProvider implements AiProvider {
  _FakeProvider(this.id, this.answer);

  final String answer;
  @override
  final String id;
  @override
  String get label => 'Fake $id';
  @override
  String get model => 'fake/$id';
  @override
  bool get isAvailable => true;

  @override
  Future<ProviderResult> getAnswer(String prompt) async => ProviderResult(
        providerId: id,
        providerLabel: label,
        model: model,
        answer: answer,
        status: ProviderStatus.success,
      );
}

void main() {
  test('app constants expose the app name', () {
    expect(AppConstants.appName, 'MDK Jarvis AI');
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

  test('local mock is dropped when a real AI answered', () async {
    final orchestrator = MultiAiOrchestrator(
      providers: <AiProvider>[
        _FakeProvider('kilo-x', 'Real answer from a real model, detailed enough.'),
        const LocalMockProvider(),
      ],
    );
    final result = await orchestrator.ask('hello');
    expect(result.winner?.providerId, 'kilo-x');
  });

  test('chat provider starts with the welcome message only', () {
    final chat = ChatProvider(
      orchestrator: MultiAiOrchestrator(
        providers: <AiProvider>[const LocalMockProvider()],
      ),
    );
    expect(chat.messages.length, 1);
    expect(chat.hasOnlyWelcome, isTrue);
  });
}
