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
  final String reason; // why this winner
}

/// Heuristic + optional LLM-synthesized judge.
/// V1: pure heuristic (no extra API call) — fast, offline, Tor-friendly.
/// V2: if Kilo available, can synthesize via `synthesizeWithLlm()`.
class JudgeService {
  JudgedResult judge(List<ProviderResult> results) {
    final successes = results.where((r) => r.isSuccess).toList();
    if (successes.isEmpty) {
      return JudgedResult(
        finalAnswer: 'Sorry, none of the AIs could answer right now. Try again or check Tor/Internet.',
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
        reason: 'Only one AI succeeded',
      );
    }

    // Heuristic scoring
    int score(ProviderResult r) {
      int s = 0;
      final a = r.answer;
      // Length sanity: 30-1200 chars ideal
      if (a.length >= 30 && a.length <= 1400) s += 20;
      else if (a.length < 20) s -= 15;
      // Structure: lists, code blocks, headers
      if (a.contains('\n-') || a.contains('\n1.') || a.contains('```')) s += 10;
      if (a.contains('##') || a.contains('**')) s += 5;
      // Relevance: if answer mentions key words from consensus (simple)
      // Consensus boost: if many answers share words, higher
      // Latency penalty: slower is less preferred
      if (r.latencyMs > 0 && r.latencyMs < 3000) s += 5;
      if (r.latencyMs > 8000) s -= 5;
      // Prefer longer reasoning models slightly? No hard bias.
      return s;
    }

    // Consensus: build word set from all successes, boost answers sharing common words
    final consensusWords = _consensusWords(successes);
    int consensusBoost(ProviderResult r) {
      final words = r.answer.toLowerCase().split(RegExp(r'\W+')).toSet();
      int overlap = words.intersection(consensusWords).length;
      return (overlap * 2).clamp(0, 20);
    }

    ProviderResult best = successes.first;
    int bestScore = score(best) + consensusBoost(best);
    for (final r in successes.skip(1)) {
      final sc = score(r) + consensusBoost(r);
      if (sc > bestScore) {
        best = r;
        bestScore = sc;
      }
    }

    return JudgedResult(
      finalAnswer: best.answer,
      winner: best,
      allAnswers: results,
      reason: 'Best of ${successes.length} • ${best.providerLabel} scored $bestScore',
    );
  }

  Set<String> _consensusWords(List<ProviderResult> successes) {
    final stop = <String>{'the', 'and', 'for', 'you', 'are', 'with', 'that', 'this', 'have', 'from', 'will', 'can', 'not', 'but', 'are', 'was', 'has', 'its', 'our', 'your'};
    final freq = <String, int>{};
    for (final r in successes) {
      final words = r.answer.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3 && !stop.contains(w)).toSet();
      for (final w in words) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }
    // Words appearing in >=2 answers
    return freq.entries.where((e) => e.value >= 2).map((e) => e.key).toSet();
  }

  /// Optional: synthesize final answer by asking one LLM to merge best candidates.
  /// Call this only if you have a spare Kilo credit and want a polished merge.
  /// For now not auto-called — keep offline judge as default.
  Future<String> synthesizeWithLlm({
    required String question,
    required List<ProviderResult> successes,
    required Future<ProviderResult> Function(String prompt) llmCall,
  }) async {
    final joined = successes.map((r) => '[${r.providerLabel}]: ${r.answer}').join('\n\n---\n\n');
    final prompt = 'User asked: "$question"\n\nHere are answers from multiple AIs:\n$joined\n\nPick the best ideas, fix errors, and synthesize ONE final concise accurate answer. No preamble.';
    final res = await llmCall(prompt);
    if (res.isSuccess) return res.answer;
    return successes.first.answer;
  }
}
