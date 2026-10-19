import 'package:flutter/material.dart';

/// An automation that can be switched on/off from the Automation tab.
/// This is UI + local state for now; wire each tool to your backend
/// (e.g. WhatsApp Business API, Gmail API, scheduler) in a service.
class AutomationTool {
  const AutomationTool({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isEnabled = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isEnabled;

  AutomationTool copyWith({bool? isEnabled}) {
    return AutomationTool(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  static const List<AutomationTool> defaults = <AutomationTool>[
    AutomationTool(
      id: 'whatsapp_auto_reply',
      title: 'WhatsApp Auto-Reply',
      description: 'Instantly reply to common customer questions on WhatsApp.',
      icon: Icons.chat_bubble_outline,
    ),
    AutomationTool(
      id: 'email_automation',
      title: 'Email Automation',
      description: 'Draft, summarise and follow up on emails automatically.',
      icon: Icons.mail_outline,
    ),
    AutomationTool(
      id: 'social_scheduler',
      title: 'Social Media Scheduler',
      description: 'Plan and schedule posts for Instagram and LinkedIn.',
      icon: Icons.schedule_outlined,
    ),
    AutomationTool(
      id: 'task_reminder',
      title: 'Daily Task Reminder',
      description: 'Get a smart morning brief of today\'s tasks and meetings.',
      icon: Icons.alarm_on_outlined,
    ),
    AutomationTool(
      id: 'lead_followup',
      title: 'Lead Follow-Up',
      description: 'Never miss a lead — automatic follow-up reminders.',
      icon: Icons.people_alt_outlined,
    ),
    AutomationTool(
      id: 'study_planner',
      title: 'AI Study Planner',
      description: 'A personalised daily study plan that adapts to you.',
      icon: Icons.school_outlined,
    ),
  ];
}
