import 'package:flutter/material.dart';

import '../models/automation_tool.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  List<AutomationTool> _tools = List<AutomationTool>.of(AutomationTool.defaults);

  void _toggle(AutomationTool tool, bool value) {
    setState(() {
      _tools = _tools
          .map((AutomationTool t) =>
              t.id == tool.id ? t.copyWith(isEnabled: value) : t)
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? '${tool.title} switched ON' : '${tool.title} switched OFF',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _tools.where((AutomationTool t) => t.isEnabled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'MDK Tech Automation Tools',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '$enabledCount of ${_tools.length} automations are ON. '
            'Switch on a tool to get started — connect each one to your '
            'backend service when you are ready to go live.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ..._tools.map(
            (AutomationTool tool) => Card(
              child: SwitchListTile(
                value: tool.isEnabled,
                onChanged: (bool v) => _toggle(tool, v),
                secondary: CircleAvatar(child: Icon(tool.icon)),
                title: Text(tool.title),
                subtitle: Text(tool.description),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
