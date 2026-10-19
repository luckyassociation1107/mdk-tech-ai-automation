import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

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
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark mode'),
            subtitle: Text(theme.isDark ? 'Dark theme is on' : 'Light theme is on'),
            value: theme.isDark,
            onChanged: theme.toggleDark,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear chat history'),
            subtitle: const Text('Remove all messages in the current chat'),
            onTap: () {
              context.read<ChatProvider>().clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('AI connection'),
            subtitle: Text(
              AppConstants.aiApiKey.isEmpty
                  ? 'Free ensemble via Kilo Gateway over Tor (no key needed)'
                  : 'Free ensemble + ${AppConstants.aiModel} (custom key)',
            ),
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
                  'MDK Jarvis AI helps you chat with an AI assistant and '
                  'automate everyday work — WhatsApp, email, social media, '
                  'tasks and study planning.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
