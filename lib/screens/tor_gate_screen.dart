import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/tor/tor_service.dart';

/// Fail-closed gate: the app child is NOT built until Tor is confirmed ready.
class TorGateScreen extends StatefulWidget {
  const TorGateScreen({super.key, required this.child});

  final Widget child;

  @override
  State<TorGateScreen> createState() => _TorGateScreenState();
}

class _TorGateScreenState extends State<TorGateScreen> {
  @override
  void initState() {
    super.initState();
    TorService.instance.addListener(_onTorChanged);
    TorService.instance.check();
  }

  @override
  void dispose() {
    TorService.instance.removeListener(_onTorChanged);
    super.dispose();
  }

  void _onTorChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tor = TorService.instance;
    if (tor.isReady) return widget.child;

    final scheme = Theme.of(context).colorScheme;
    final checking = tor.status == TorStatus.checking || tor.status == TorStatus.unknown;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(checking ? Icons.hourglass_top : Icons.shield, size: 64, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                checking ? 'Checking Tor…' : 'Tor Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                checking
                    ? 'Connecting to Orbot at 127.0.0.1:9050'
                    : tor.lastError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: checking ? null : () => tor.check(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(tor.orbotPlayStoreUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.download),
                label: const Text('Get Orbot (Play Store)'),
              ),
              const SizedBox(height: 12),
              Text(
                'This app works only through Tor. It will not connect '
                'without Orbot running.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
