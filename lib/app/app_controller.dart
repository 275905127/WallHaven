// lib/app/app_controller.dart
import 'dart:async';

import '../theme/theme_store.dart';
import 'app_effect.dart';
import 'app_intent.dart';

class AppController {
  final ThemeStore store;

  final _effects = StreamController<AppEffect>.broadcast();
  Stream<AppEffect> get effects => _effects.stream;

  AppController({required this.store});

  void dispatch(AppIntent intent) {
    switch (intent) {
      // -------- Navigation --------
      case OpenSettingsIntent():
        _effects.add(const NavigateToSettingsEffect());
        return;

      case OpenPersonalizationIntent():
        _effects.add(const NavigateToPersonalizationEffect());
        return;

      case PopRouteIntent():
        _effects.add(const PopRouteEffect());
        return;

      case OpenDrawerIntent():
        _effects.add(const OpenDrawerEffect());
        return;

      case CloseDrawerIntent():
        _effects.add(const CloseDrawerEffect());
        return;

      // -------- Theme actions (write store) --------
      case SetPreferredModeIntent(mode: final m):
        store.setPreferredMode(m);
        return;

      case SetEnableThemeModeIntent(enabled: final v):
        store.setEnableThemeMode(v);
        return;

      case SetEnableCustomColorsIntent(enabled: final v):
        store.setEnableCustomColors(v);
        return;

      case SetAccentIntent(color: final c, name: final n):
        store.setAccent(c, n);
        return;

      case SetCardRadiusIntent(value: final v):
        store.setCardRadius(v);
        return;

      case SetImageRadiusIntent(value: final v):
        store.setImageRadius(v);
        return;

      case SetCustomBackgroundColorIntent(color: final c):
        store.setCustomBackgroundColor(c);
        return;

      case SetCustomCardColorIntent(color: final c):
        store.setCustomCardColor(c);
        return;
    }
  }

  void dispose() {
    _effects.close();
  }
}