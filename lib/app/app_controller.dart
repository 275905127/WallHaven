// lib/app/app_controller.dart
import 'dart:async';

import 'app_effect.dart';
import 'app_intent.dart';

class AppController {
  final _effects = StreamController<AppEffect>.broadcast();

  Stream<AppEffect> get effects => _effects.stream;

  void dispatch(AppIntent intent) {
    switch (intent) {
      case OpenSettingsIntent():
        _effects.add(const NavigateToSettingsEffect());
        break;

      case OpenDrawerIntent():
        _effects.add(const OpenDrawerEffect());
        break;

      case CloseDrawerIntent():
        _effects.add(const CloseDrawerEffect());
        break;
    }
  }

  void dispose() {
    _effects.close();
  }
}