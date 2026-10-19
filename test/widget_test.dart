import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mdk_tech_ai_automation/app.dart';
import 'package:mdk_tech_ai_automation/core/constants/app_constants.dart';
import 'package:mdk_tech_ai_automation/providers/chat_provider.dart';
import 'package:mdk_tech_ai_automation/providers/theme_provider.dart';

void main() {
  testWidgets('App shows splash with app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const MdkJarvisApp(),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);

    // Let the 2-second splash timer finish so no timers are left pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
