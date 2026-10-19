/// Central place for app-wide constants.
///
/// To connect a real AI backend, run with:
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
      'Ask me anything — I consult multiple AIs and pick the best answer for you. '
      'Tap a suggestion below to get started.';

  /// Read at compile time. Empty = use free ensemble (Kilo + Duck.ai + local mock).
  static const String aiApiKey = String.fromEnvironment('AI_API_KEY');
  static const String aiApiUrl = String.fromEnvironment(
    'AI_API_URL',
    defaultValue: 'https://api.openai.com/v1/chat/completions',
  );
  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  // --- Kilo Gateway (keyless free tier) ---
  static const String kiloGatewayUrl = String.fromEnvironment(
    'KILO_GATEWAY_URL',
    defaultValue: 'https://api.kilo.ai/api/gateway',
  );
  static const String kiloApiKey = String.fromEnvironment('KILO_API_KEY');
  // Free models that work anonymously (200 req/hour/IP)
  static const List<String> kiloFreeModels = <String>[
    'z-ai/glm-5:free',
    'deepseek/deepseek-r1-0528:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'qwen/qwen3-coder:free',
  ];

  /// Free model used for the optional "synthesize best answer" step.
  static const String kiloSynthesisModel = 'kilo-auto/free';

  // --- WebView providers (no-login) ---
  static const String duckAiUrl = 'https://duck.ai';
  static const String chatQwenUrl = 'https://chat.qwen.ai';
  static const String chatGptUrl = 'https://chatgpt.com';
  static const String geminiUrl = 'https://gemini.google.com';
  static const String arenaUrl = 'https://arena.ai';

  // --- Tor ---
  static const String torSocksHost = '127.0.0.1';
  static const int torSocksPort = 9050;
  static const int torHttpPort = 8118;
  static const String torCheckUrl = 'https://check.torproject.org/api/ip';

  static const List<String> suggestionPrompts = <String>[
    'Who are you?',
    'What automation can you do?',
    'Help me learn Flutter',
    'Give me a study plan',
    'Automate my WhatsApp replies',
    'Compare AIs: explain quantum computing',
  ];

  /// Preset browsers for Manual Browser tab
  static const List<BrowserPreset> browserPresets = <BrowserPreset>[
    BrowserPreset(
      id: 'duck',
      label: 'Duck.ai',
      url: duckAiUrl,
      subtitle: 'No login • Multi-model • Private',
      icon: '🦆',
    ),
    BrowserPreset(
      id: 'kilo',
      label: 'Kilo Gateway',
      url: 'https://kilo.ai/docs',
      subtitle: 'Free API docs • 500+ models',
      icon: '⚡',
    ),
    BrowserPreset(
      id: 'qwen',
      label: 'Qwen Chat',
      url: chatQwenUrl,
      subtitle: 'Alibaba • Login required',
      icon: '🧠',
    ),
    BrowserPreset(
      id: 'chatgpt',
      label: 'ChatGPT',
      url: chatGptUrl,
      subtitle: 'OpenAI • Login required',
      icon: '💬',
    ),
    BrowserPreset(
      id: 'gemini',
      label: 'Gemini',
      url: geminiUrl,
      subtitle: 'Google • Login required',
      icon: '✨',
    ),
    BrowserPreset(
      id: 'arena',
      label: 'Arena.ai',
      url: arenaUrl,
      subtitle: 'Leaderboard • reCAPTCHA',
      icon: '🏆',
    ),
  ];
}

class BrowserPreset {
  const BrowserPreset({
    required this.id,
    required this.label,
    required this.url,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String url;
  final String subtitle;
  final String icon;
}
