import 'package:flutter/material.dart';

// 1. 状态核心 (ChangeNotifier)
class ThemeStore extends ChangeNotifier {
  // 默认状态
  ThemeMode _mode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";

  // 获取数据的 Getter
  ThemeMode get mode => _mode;
  Color get accentColor => _accentColor;
  String get accentName => _accentName;

  // 修改主题模式
  void setMode(ThemeMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners(); // 通知全 App 重绘
    }
  }

  // 修改重点色
  void setAccent(Color newColor, String newName) {
    if (_accentColor != newColor) {
      _accentColor = newColor;
      _accentName = newName;
      notifyListeners(); // 通知全 App 重绘
    }
  }
}

// 2. 状态注入器 (InheritedWidget)
// 这让我们可以在任何地方通过 context 找到 ThemeStore
class ThemeScope extends InheritedWidget {
  final ThemeStore store;

  const ThemeScope({
    super.key,
    required this.store,
    required super.child,
  });

  // 方便调用的静态方法：ThemeScope.of(context)
  static ThemeStore of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) {
    return store != oldWidget.store;
  }
}
