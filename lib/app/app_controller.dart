// lib/app/app_controller.dart
import 'dart:async';

import '../theme/theme_store.dart';
import 'app_effect.dart';
import 'app_intent.dart';

class AppController {
  final ThemeStore store;

  final StreamController<AppEffect> _eff = StreamController<AppEffect>.broadcast();

  Stream<AppEffect> get effects => _eff.stream;

  AppController({required this.store});

  void dispatch(AppIntent intent) {
    switch (intent) {
      case OpenSettingsIntent():
        _eff.add(const NavigateToSettingsEffect());
        return;

      case OpenPersonalizationIntent():
        _eff.add(const NavigateToPersonalizationEffect());
        return;

      case OpenDrawerIntent():
        _eff.add(const OpenDrawerEffect());
        return;

      case CloseDrawerIntent():
        _eff.add(const CloseDrawerEffect());
        return;

      case PopRouteIntent():
        _eff.add(const PopRouteEffect());
        return;
    }
  }

  void dispose() {
    _eff.close();
  }
}