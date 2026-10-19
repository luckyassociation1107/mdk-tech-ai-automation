import 'package:flutter/material.dart';
import '../models/provider_result.dart';

class ProviderAnswerSheet extends StatelessWidget {
  const ProviderAnswerSheet({
    super.key,
    required this.winner,
    required this.allAnswers,
    required this.reason,
  });

  final ProviderResult? winner;
  final List<ProviderResult> allAnswers;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final successes = allAnswers.where((r) => r.isSuccess).toList();
    final others = allAnswers.where((r) => !r.isSuccess).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.verified, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Judged Result', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(reason, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (winner != null)
            Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, size: 16, color: scheme.onPrimaryContainer),
                        const SizedBox(width: 6),
                        Text('Winner: ${winner!.providerLabel}', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                        const Spacer(),
                        Text('${winner!.latencyMs}ms', style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(winner!.model, style: TextStyle(fontSize: 11, color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 8),
                    Text(winner!.answer, style: TextStyle(color: scheme.onPrimaryContainer)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('All answers (${successes.length} ok / ${allAnswers.length} total)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final r in successes)
            Card(
              child: ExpansionTile(
                title: Text(r.providerLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${r.model} • ${r.latencyMs}ms', style: const TextStyle(fontSize: 11)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SelectableText(r.answer),
                  ),
                ],
              ),
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Skipped / failed', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.error)),
            for (final r in others)
              ListTile(
                dense: true,
                title: Text(r.providerLabel),
                subtitle: Text(r.errorMessage ?? r.status.name),
                trailing: Icon(
                  r.status == ProviderStatus.skipped ? Icons.skip_next : Icons.error_outline,
                  size: 18,
                ),
              ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
