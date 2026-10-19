import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/tor_gate_screen.dart';

class MdkJarvisApp extends StatelessWidget {
  const MdkJarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.themeMode,
      home: const TorGateScreen(child: SplashScreen()),
    );
  }
}
