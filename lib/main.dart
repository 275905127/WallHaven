import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'theme/theme_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  final themeStore = ThemeStore();

  runApp(
    ThemeScope(
      store: themeStore,
      child: const App(),
    ),
  );
}