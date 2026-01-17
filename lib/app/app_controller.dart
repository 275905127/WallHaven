// lib/app/app_controller.dart
import 'package:flutter/foundation.dart';

import 'app_intent.dart';

enum AppRoute {
  home,
  settings,
}

class AppController extends ChangeNotifier {
  AppRoute _route = AppRoute.home;
  bool _drawerOpen = false;

  AppRoute get route => _route;
  bool get drawerOpen => _drawerOpen;

  void dispatch(AppIntent intent) {
    switch (intent) {
      case OpenDrawer():
        _drawerOpen = true;
        notifyListeners();
        return;

      case CloseDrawer():
        _drawerOpen = false;
        notifyListeners();
        return;

      case GoHome():
        _route = AppRoute.home;
        _drawerOpen = false;
        notifyListeners();
        return;

      case GoSettings():
        _route = AppRoute.settings;
        _drawerOpen = false;
        notifyListeners();
        return;
    }
  }
}