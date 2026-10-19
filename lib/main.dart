import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage/chat_storage.dart';
import 'services/storage/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = await SettingsProvider.load(prefs: prefs);
  final storage = ChatStorage(prefs);
  final chat = ChatProvider(
    settings: settings,
    storage: storage,
    initial: storage.load(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ChatProvider>.value(value: chat),
      ],
      child: const MdkJarvisApp(),
    ),
  );
}
