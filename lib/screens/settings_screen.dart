import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../services/orchestrator/ensemble_config.dart';
import '../services/storage/settings_provider.dart';
import '../services/tor/tor_circuit_manager.dart';
import '../services/tor/tor_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final cfg = settings.config;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.smart_toy)),
            title: Text(AppConstants.appName),
            subtitle: Text(AppConstants.appTagline),
          ),
          const Divider(),
          const _Header('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: Text(theme.isDark ? 'Dark theme is on' : 'Light theme is on'),
            value: theme.isDark,
            onChanged: theme.toggleDark,
          ),
          const _Header('Tor (mandatory)'),
          AnimatedBuilder(
            animation: TorService.instance,
            builder: (BuildContext context, Widget? _) {
              final tor = TorService.instance;
              return ListTile(
                leading: Icon(tor.isReady ? Icons.lock : Icons.lock_open),
                title: Text(tor.isReady ? 'Tor verified' : 'Tor not verified'),
                subtitle: Text(
                  tor.isReady
                      ? 'Traffic is confirmed to exit via Tor'
                      : (tor.lastError.isEmpty ? 'Not checked yet' : tor.lastError),
                ),
                trailing: IconButton(
                  tooltip: 'Re-check',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => TorService.instance.check(),
                ),
              );
            },
          ),
          const _Header('Tor circuit'),
          AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              TorCircuitManager.instance,
              TorService.instance,
            ]),
            builder: (BuildContext context, Widget? _) {
              final circuits = TorCircuitManager.instance;
              return ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('New Tor circuit'),
                subtitle: Text(
                  'Exit IP: ${TorService.instance.exitIp ?? 'unknown'} • '
                  'new circuits this session: ${circuits.rotations}. '
                  'Each AI model already uses its own circuit.',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    circuits.newIdentity();
                    // Re-verify through the new circuits to show the new exit IP.
                    // If Tor fails, the gate screen blocks the app (fail-closed).
                    await TorService.instance.check(silent: true);
                  },
                  child: const Text('New'),
                ),
              );
            },
          ),
          const _Header('Free AI models (no login, no key)'),
          for (final String m in AppConstants.kiloFreeModels)
            SwitchListTile(
              title: Text(m),
              subtitle: const Text('Kilo Gateway • free tier'),
              value: cfg.kiloModels.contains(m),
              onChanged: (bool v) => settings.setKiloModelEnabled(m, v),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.science_outlined),
            title: const Text('Duck.ai (experimental)'),
            subtitle: const Text(
              'Drives duck.ai in a hidden Tor WebView. Slow, and may break when '
              'the site changes. Check duck.ai\'s terms before turning on.',
            ),
            value: cfg.duckAiEnabled,
            onChanged: (bool v) => settings.setDuckAiEnabled(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_fix_high_outlined),
            title: const Text('Synthesize best answer'),
            subtitle: const Text(
              'Merge the model answers with one extra free call. Slower, usually better.',
            ),
            value: cfg.synthesisEnabled,
            onChanged: (bool v) => settings.setSynthesisEnabled(v),
          ),
          if (cfg.kiloModels.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'No free models enabled. Only the offline fallback will answer.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          const _Header('Custom AI (optional)'),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('OpenAI-compatible endpoint'),
            subtitle: Text(
              cfg.hasCustom
                  ? '${cfg.customModel} • ${Uri.tryParse(cfg.customUrl)?.host ?? 'custom'} • key stored securely'
                  : 'Not set. Free models are used by default.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog<void>(
              context: context,
              builder: (BuildContext _) => _CustomProviderDialog(initial: cfg),
            ),
          ),
          const _Header('Chat'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear chat history'),
            subtitle: const Text('Removes all messages from this device'),
            onTap: () async {
              await context.read<ChatProvider>().clearChat();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat cleared')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text(
              'Version ${AppConstants.appVersion} • ${AppConstants.companyName}',
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
              applicationLegalese: '© ${AppConstants.companyName}',
              children: const <Widget>[
                SizedBox(height: 12),
                Text(
                  'MDK Jarvis AI sends your question through Tor to several free '
                  'AI models and shows the best answer. Automation tools are demo only.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _CustomProviderDialog extends StatefulWidget {
  const _CustomProviderDialog({required this.initial});
  final EnsembleConfig initial;

  @override
  State<_CustomProviderDialog> createState() => _CustomProviderDialogState();
}

class _CustomProviderDialogState extends State<_CustomProviderDialog> {
  late final TextEditingController _url =
      TextEditingController(text: widget.initial.customUrl);
  late final TextEditingController _model =
      TextEditingController(text: widget.initial.customModel);
  late final TextEditingController _key =
      TextEditingController(text: widget.initial.customKey);

  @override
  void dispose() {
    _url.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settings = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);
    await settings.saveCustom(
      url: _url.text,
      model: _model.text,
      key: _key.text,
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom AI endpoint'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'Chat completions URL',
                hintText: 'https://api.example.com/v1/chat/completions',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _key,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API key',
                helperText: 'Stored in secure storage on this device',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            final settings = context.read<SettingsProvider>();
            final navigator = Navigator.of(context);
            await settings.saveCustom(url: '', model: '', key: '');
            navigator.pop();
          },
          child: const Text('Remove'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
