import 'package:flutter/widgets.dart';

import 'theme_store.dart';

class ThemeScope extends InheritedWidget {
  final ThemeStore store;

  const ThemeScope({
    super.key,
    required this.store,
    required super.child,
  });

  static ThemeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    if (scope == null) throw FlutterError('ThemeScope not found in widget tree');
    return scope.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => !identical(store, oldWidget.store);
}