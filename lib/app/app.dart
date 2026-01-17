import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../theme/theme_store.dart';
import 'app_shell.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final customBg = store.enableCustomColors ? store.customBackgroundColor : null;
        final customCard = store.enableCustomColors ? store.customCardColor : null;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: store.mode,
          theme: AppTheme.light(
            store.accentColor,
            customBg: customBg,
            customCard: customCard,
            cardRadius: store.cardRadius,
          ),
          darkTheme: AppTheme.dark(
            store.accentColor,
            customBg: customBg,
            customCard: customCard,
            cardRadius: store.cardRadius,
          ),
          home: const AppShell(),
        );
      },
    );
  }
}