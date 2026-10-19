/// Central place for app-wide constants.
///
/// To connect a real AI backend later, run the app with:
/// flutter run --dart-define=AI_API_KEY=your_key --dart-define=AI_API_URL=https://api.openai.com/v1/chat/completions
/// Never hard-code or commit a real API key in source code.
class AppConstants {
  AppConstants._();

  static const String appName = 'MDK Jarvis AI';
  static const String appTagline = 'Your personal AI assistant by MDK Tech';
  static const String companyName = 'MDK Tech';
  static const String appVersion = '1.0.0';

  static const String welcomeMessage =
      'Hello! I\'m Jarvis, your AI assistant from MDK Tech. '
      'Ask me anything — or tap a suggestion below to get started.';

  /// Read at compile time. Empty = use the built-in local mock AI.
  static const String aiApiKey = String.fromEnvironment('AI_API_KEY');
  static const String aiApiUrl = String.fromEnvironment(
    'AI_API_URL',
    defaultValue: 'https://api.openai.com/v1/chat/completions',
  );
  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  static const List<String> suggestionPrompts = <String>[
    'Who are you?',
    'What automation can you do?',
    'Help me learn Flutter',
    'Give me a study plan',
    'Automate my WhatsApp replies',
  ];
}
