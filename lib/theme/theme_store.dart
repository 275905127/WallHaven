import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_source.dart';

// 🌟 全局 ThemeScope：提供 store，但不再“找不到就 new 一个影子 store”
class ThemeScope extends InheritedWidget {
  final ThemeStore store;
  const ThemeScope({super.key, required this.store, required super.child});

  static ThemeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    if (scope == null) {
      throw FlutterError('ThemeScope not found in widget tree');
    }
    return scope.store;
  }

  static ThemeStore? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeScope>()?.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => identical(store, oldWidget.store) == false;
}

class ThemeStore extends ChangeNotifier {
  // === 状态数据 ===
  ThemeMode _mode = ThemeMode.system;

  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";

  double _cardRadius = 16.0;
  double _imageRadius = 12.0;

  bool _enableCustomColors = false;
  Color? _customBackgroundColor;
  Color? _customCardColor;

  List<ImageSource> _sources = [ImageSource.wallhaven];
  late ImageSource _currentSource;

  // 保存去抖，避免疯狂写 prefs
  Timer? _saveDebounce;

  // === Getters ===
  ThemeMode get mode => _mode;

  Color get accentColor => _accentColor;
  String get accentName => _accentName;

  double get cardRadius => _cardRadius;
  double get imageRadius => _imageRadius;

  bool get enableCustomColors => _enableCustomColors;

  Color? get customBackgroundColor => _customBackgroundColor;
  Color? get customCardColor => _customCardColor;

  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _currentSource;

  ThemeStore() {
    _currentSource = _sources.first;
    _loadFromPrefs();
  }

  // === Actions ===

  void setMode(ThemeMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    savePreferences();
  }

  void setAccent(Color newColor, String newName) {
    if (_accentColor.value == newColor.value && _accentName == newName) return;
    _accentColor = newColor;
    _accentName = newName;
    notifyListeners();
    savePreferences();
  }

  void setEnableCustomColors(bool value) {
    if (_enableCustomColors == value) return;
    _enableCustomColors = value;
    notifyListeners();
    savePreferences();
  }

  void setCardRadius(double radius) {
    if (_cardRadius == radius) return;
    _cardRadius = radius;
    notifyListeners(); // 让 slider/圆角实时刷新
  }

  void setImageRadius(double radius) {
    if (_imageRadius == radius) return;
    _imageRadius = radius;
    notifyListeners();
  }

  void setCustomBackgroundColor(Color? color) {
    if (_customBackgroundColor?.value == color?.value) return;
    _customBackgroundColor = color;
    notifyListeners();
    savePreferences();
  }

  void setCustomCardColor(Color? color) {
    if (_customCardColor?.value == color?.value) return;
    _customCardColor = color;
    notifyListeners();
    savePreferences();
  }

  void setSource(ImageSource source) {
    if (_currentSource.id == source.id) return;
    _currentSource = source;
    notifyListeners();
    savePreferences();
  }

  void addSource(String name, String url, {String? username, String? apiKey}) {
    final newSource = ImageSource(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      baseUrl: _normalizeBaseUrl(url),
      username: _normalizeOptional(username),
      apiKey: _normalizeOptional(apiKey),
    );
    _sources.add(newSource);
    notifyListeners();
    savePreferences();
  }

  void updateSource(ImageSource updatedSource) {
    final index = _sources.indexWhere((s) => s.id == updatedSource.id);
    if (index == -1) return;

    // 统一：baseUrl normalize；username/apiKey 统一用 null 表示“未配置”
    final fixed = updatedSource.copyWith(
      baseUrl: _normalizeBaseUrl(updatedSource.baseUrl),
      username: _normalizeOptional(updatedSource.username),
      apiKey: _normalizeOptional(updatedSource.apiKey),
    );

    _sources[index] = fixed;
    if (_currentSource.id == fixed.id) {
      _currentSource = fixed;
    }
    notifyListeners();
    savePreferences();
  }

  void removeSource(String id) {
    if (id == ImageSource.wallhaven.id) return;
    _sources.removeWhere((s) => s.id == id);

    if (_currentSource.id == id) {
      _currentSource = _sources.firstWhere(
        (s) => s.id == ImageSource.wallhaven.id,
        orElse: () => _sources.first,
      );
    }

    notifyListeners();
    savePreferences();
  }

  // === 持久化逻辑 ===
  Future<void> savePreferences() async {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 120), () async {
      final prefs = await SharedPreferences.getInstance();

      prefs.setInt('theme_mode', _mode.index);

      // ✅ 之前没持久化：导致重启丢失
      prefs.setInt('accent_color', _accentColor.value);
      prefs.setString('accent_name', _accentName);

      prefs.setBool('enable_custom_colors', _enableCustomColors);
      prefs.setDouble('card_radius', _cardRadius);
      prefs.setDouble('image_radius', _imageRadius);

      if (_customBackgroundColor != null) {
        prefs.setInt('custom_bg_color', _customBackgroundColor!.value);
      } else {
        prefs.remove('custom_bg_color');
      }

      if (_customCardColor != null) {
        prefs.setInt('custom_card_color', _customCardColor!.value);
      } else {
        prefs.remove('custom_card_color');
      }

      prefs.setStringList('image_sources', _sources.map((s) => jsonEncode(s.toJson())).toList());
      prefs.setString('current_source_id', _currentSource.id);
    });
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _mode = ThemeMode.values[modeIndex];
      }

      final accentVal = prefs.getInt('accent_color');
      if (accentVal != null) _accentColor = Color(accentVal);
      _accentName = prefs.getString('accent_name') ?? _accentName;

      _enableCustomColors = prefs.getBool('enable_custom_colors') ?? false;
      _cardRadius = prefs.getDouble('card_radius') ?? 16.0;
      _imageRadius = prefs.getDouble('image_radius') ?? 12.0;

      final bgVal = prefs.getInt('custom_bg_color');
      _customBackgroundColor = bgVal != null ? Color(bgVal) : null;

      final cardVal = prefs.getInt('custom_card_color');
      _customCardColor = cardVal != null ? Color(cardVal) : null;

      final sourcesJson = prefs.getStringList('image_sources');
      if (sourcesJson != null) {
        final loadedSources = sourcesJson
            .map((e) => ImageSource.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .toList();

        loadedSources.removeWhere((s) => s.id == ImageSource.wallhaven.id);
        _sources = [ImageSource.wallhaven, ...loadedSources];
      }

      final currentSourceId = prefs.getString('current_source_id');
      if (currentSourceId != null) {
        _currentSource = _sources.firstWhere(
          (s) => s.id == currentSourceId,
          orElse: () => _sources.first,
        );
      } else {
        _currentSource = _sources.first;
      }
    } catch (e) {
      debugPrint("Load Prefs Error: $e");
    } finally {
      notifyListeners();
    }
  }

  String _normalizeBaseUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  String? _normalizeOptional(String? v) {
    if (v == null) return null;
    final t = v.trim();
    if (t.isEmpty) return null;
    return t;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }
}