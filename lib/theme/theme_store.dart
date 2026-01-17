import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeScope extends InheritedWidget {
  final ThemeStore store;

  const ThemeScope({
    super.key,
    required this.store,
    required super.child,
  });

  static ThemeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    if (scope == null) throw FlutterError('ThemeScope not found in widget tree');
    return scope.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => !identical(store, oldWidget.store);
}

class ThemeStore extends ChangeNotifier {
  // ===== persisted keys =====
  static const _kThemeMode = 'theme_mode';
  static const _kEnableThemeMode = 'enable_theme_mode';
  static const _kAccentColor = 'accent_color';
  static const _kAccentName = 'accent_name';
  static const _kEnableCustomColors = 'enable_custom_colors';
  static const _kCardRadius = 'card_radius';
  static const _kImageRadius = 'image_radius';
  static const _kCustomBg = 'custom_bg_color';
  static const _kCustomCard = 'custom_card_color';

  // ===== Theme =====
  ThemeMode _mode = ThemeMode.system;
  ThemeMode _preferredMode = ThemeMode.system;
  bool _enableThemeMode = true;

  Color _accentColor = Colors.blue;
  String _accentName = '蓝色';

  double _cardRadius = 16.0;
  double _imageRadius = 12.0;

  bool _enableCustomColors = false;
  Color? _customBackgroundColor;
  Color? _customCardColor;

  Timer? _saveDebounce;

  ThemeMode get mode => _mode;
  ThemeMode get preferredMode => _preferredMode;
  bool get enableThemeMode => _enableThemeMode;

  Color get accentColor => _accentColor;
  String get accentName => _accentName;

  double get cardRadius => _cardRadius;
  double get imageRadius => _imageRadius;

  bool get enableCustomColors => _enableCustomColors;
  Color? get customBackgroundColor => _customBackgroundColor;
  Color? get customCardColor => _customCardColor;

  ThemeStore() {
    _loadFromPrefs();
  }

  void _recomputeEffectiveMode() {
    if (_enableCustomColors) {
      _mode = ThemeMode.light; // 自定义色强制走 light（跟你原来的逻辑一致）
      return;
    }
    _mode = _enableThemeMode ? _preferredMode : ThemeMode.system;
  }

  // ===== actions =====
  void setPreferredMode(ThemeMode newMode) {
    if (_preferredMode == newMode) return;
    _preferredMode = newMode;
    _recomputeEffectiveMode();
    notifyListeners();
    savePreferences();
  }

  void setEnableThemeMode(bool value) {
    if (_enableThemeMode == value) return;
    _enableThemeMode = value;
    _recomputeEffectiveMode();
    notifyListeners();
    savePreferences();
  }

  void setAccent(Color newColor, String newName) {
    if (_accentColor.toARGB32() == newColor.toARGB32() && _accentName == newName) return;
    _accentColor = newColor;
    _accentName = newName;
    notifyListeners();
    savePreferences();
  }

  void setCardRadius(double radius) {
    if (_cardRadius == radius) return;
    _cardRadius = radius;
    notifyListeners();
    savePreferences();
  }

  void setImageRadius(double radius) {
    if (_imageRadius == radius) return;
    _imageRadius = radius;
    notifyListeners();
    savePreferences();
  }

  void setEnableCustomColors(bool value) {
    if (_enableCustomColors == value) return;
    _enableCustomColors = value;
    _recomputeEffectiveMode();
    notifyListeners();
    savePreferences();
  }

  void setCustomBackgroundColor(Color? color) {
    if (_customBackgroundColor?.toARGB32() == color?.toARGB32()) return;
    _customBackgroundColor = color;
    notifyListeners();
    savePreferences();
  }

  void setCustomCardColor(Color? color) {
    if (_customCardColor?.toARGB32() == color?.toARGB32()) return;
    _customCardColor = color;
    notifyListeners();
    savePreferences();
  }

  // ===== persist =====
  Future<void> savePreferences() async {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 120), () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_kThemeMode, _preferredMode.index);
      await prefs.setBool(_kEnableThemeMode, _enableThemeMode);

      await prefs.setInt(_kAccentColor, _accentColor.toARGB32());
      await prefs.setString(_kAccentName, _accentName);

      await prefs.setBool(_kEnableCustomColors, _enableCustomColors);
      await prefs.setDouble(_kCardRadius, _cardRadius);
      await prefs.setDouble(_kImageRadius, _imageRadius);

      if (_customBackgroundColor != null) {
        await prefs.setInt(_kCustomBg, _customBackgroundColor!.toARGB32());
      } else {
        await prefs.remove(_kCustomBg);
      }

      if (_customCardColor != null) {
        await prefs.setInt(_kCustomCard, _customCardColor!.toARGB32());
      } else {
        await prefs.remove(_kCustomCard);
      }
    });
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final modeIndex = prefs.getInt(_kThemeMode) ?? ThemeMode.system.index;
      _preferredMode = (modeIndex >= 0 && modeIndex < ThemeMode.values.length)
          ? ThemeMode.values[modeIndex]
          : ThemeMode.system;

      _enableThemeMode = prefs.getBool(_kEnableThemeMode) ?? true;

      final accentVal = prefs.getInt(_kAccentColor);
      if (accentVal != null) _accentColor = Color(accentVal);
      _accentName = prefs.getString(_kAccentName) ?? _accentName;

      _enableCustomColors = prefs.getBool(_kEnableCustomColors) ?? false;
      _cardRadius = prefs.getDouble(_kCardRadius) ?? 16.0;
      _imageRadius = prefs.getDouble(_kImageRadius) ?? 12.0;

      final bgVal = prefs.getInt(_kCustomBg);
      _customBackgroundColor = bgVal != null ? Color(bgVal) : null;

      final cardVal = prefs.getInt(_kCustomCard);
      _customCardColor = cardVal != null ? Color(cardVal) : null;

      _recomputeEffectiveMode();
    } catch (_) {
      // 别在这里炸用户
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}