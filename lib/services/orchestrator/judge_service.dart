import '../../models/provider_result.dart';

class JudgedResult {
  const JudgedResult({
    required this.finalAnswer,
    required this.winner,
    required this.allAnswers,
    required this.reason,
  });

  final String finalAnswer;
  final ProviderResult? winner;
  final List<ProviderResult> allAnswers;
  final String reason;
}

/// Heuristic judge: picks the best of several successful answers.
/// It rewards sane length, structure, low latency and agreement with the other
/// answers. It does NOT verify facts.
class JudgeService {
  static const Set<String> _stopWords = <String>{
    'the', 'and', 'for', 'you', 'are', 'with', 'that', 'this', 'have', 'from',
    'will', 'can', 'not', 'but', 'was', 'has', 'its', 'our', 'your',
  };

  JudgedResult judge(List<ProviderResult> results) {
    final successes = results.where((ProviderResult r) => r.isSuccess).toList();
    if (successes.isEmpty) {
      return JudgedResult(
        finalAnswer:
            'Sorry, none of the AI models could answer right now. Check Orbot and your connection, then try again.',
        winner: null,
        allAnswers: results,
        reason: 'No successful answers',
      );
    }
    if (successes.length == 1) {
      return JudgedResult(
        finalAnswer: successes.first.answer,
        winner: successes.first,
        allAnswers: results,
        reason: 'Only ${successes.first.providerLabel} answered',
      );
    }

    final consensus = _consensusWords(successes);

    ProviderResult best = successes.first;
    int bestScore = _score(best, consensus);
    for (final ProviderResult r in successes.skip(1)) {
      final sc = _score(r, consensus);
      if (sc > bestScore) {
        best = r;
        bestScore = sc;
      }
    }

    return JudgedResult(
      finalAnswer: best.answer,
      winner: best,
      allAnswers: results,
      reason:
          'Best of ${successes.length} • ${best.providerLabel} scored $bestScore',
    );
  }

  int _score(ProviderResult r, Set<String> consensus) {
    int s = 0;
    final a = r.answer;
    if (a.length >= 30 && a.length <= 1400) {
      s += 20;
    } else if (a.length < 20) {
      s -= 15;
    }
    if (a.contains('\n-') || a.contains('\n1.') || a.contains('```')) s += 10;
    if (a.contains('##') || a.contains('**')) s += 5;
    if (r.latencyMs > 0 && r.latencyMs < 3000) s += 5;
    if (r.latencyMs > 8000) s -= 5;
    final words = _words(a).toSet();
    s += (words.intersection(consensus).length * 2).clamp(0, 20);
    return s;
  }

  Iterable<String> _words(String text) => text
      .toLowerCase()
      .split(RegExp(r'\W+'))
      .where((String w) => w.length > 3 && !_stopWords.contains(w));

  /// Words that appear in at least two successful answers.
  Set<String> _consensusWords(List<ProviderResult> successes) {
    final freq = <String, int>{};
    for (final ProviderResult r in successes) {
      for (final String w in _words(r.answer).toSet()) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }
    return freq.entries
        .where((MapEntry<String, int> e) => e.value >= 2)
        .map((MapEntry<String, int> e) => e.key)
        .toSet();
  }

  /// Prompt for the LLM synthesis step: merge several candidate answers into one.
  static String buildSynthesisPrompt(
    String question,
    List<ProviderResult> answers,
  ) {
    final joined = answers
        .map((ProviderResult r) => '[Candidate from ${r.providerLabel}]\n${r.answer}')
        .join('\n\n');
    return 'Question: "$question"\n\n'
        'Candidate answers:\n\n$joined\n\n'
        'Write ONE final answer to the question. Keep what is correct, drop what '
        'is wrong or contradictory, and merge the best points. Do not mention the '
        'candidates or these instructions. Reply in the same language as the question.';
  }
}
