// lib/theme/theme_store.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/http/http_client.dart';
import '../data/source_factory.dart';
import '../domain/entities/source_capabilities.dart';
import '../sources/source_plugin.dart';
import '../sources/source_registry.dart';

// ----------------------------
// ThemeScope
// ----------------------------
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

// ----------------------------
// ThemeStore
// ----------------------------
class ThemeStore extends ChangeNotifier {
  // ✅ 单例化：不要在 getter 里 new
  final HttpClient _http = HttpClient();
  late final SourceFactory _factory = SourceFactory(http: _http);

  // ===== Theme =====
  ThemeMode _mode = ThemeMode.system;
  ThemeMode _preferredMode = ThemeMode.system;
  bool _enableThemeMode = true;

  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";

  double _cardRadius = 16.0;
  double _imageRadius = 12.0;

  bool _enableCustomColors = false;
  Color? _customBackgroundColor;
  Color? _customCardColor;

  Timer? _saveDebounce;

  // ===== Source (插件化最终形态) =====
  final SourceRegistry _registry = SourceRegistry.defaultRegistry();

  List<SourceConfig> _sourceConfigs = const [];
  late SourceConfig _currentConfig;

  // ✅ capabilities 缓存：避免 getter 每次都 fromStore() 造对象
  String? _capsCacheForConfigId;
  SourceCapabilities? _capsCache;

  void _invalidateCapsCache() {
    _capsCacheForConfigId = null;
    _capsCache = null;
  }

  // ===== Getters =====
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

  List<SourceConfig> get sourceConfigs => _sourceConfigs;
  SourceConfig get currentSourceConfig => _currentConfig;

  SourcePlugin get currentPlugin {
    final p = _registry.plugin(_currentConfig.pluginId);
    if (p == null) throw StateError('Plugin not found: ${_currentConfig.pluginId}');
    return p;
  }

  /// 给业务层用：拿到当前插件的“已清洗 settings”
  Map<String, dynamic> get currentSettings => currentPlugin.sanitizeSettings(_currentConfig.settings);

  /// ✅ 给 UI 用：当前 source 的 capabilities（用于动态筛选 UI）
  ///
  /// 注意：这玩意会在 UI rebuild 时被频繁访问，所以必须避免每次都 new source。
  SourceCapabilities get currentCapabilities {
    final id = _currentConfig.id;
    if (_capsCacheForConfigId == id && _capsCache != null) return _capsCache!;

    final src = _factory.fromStore(this);
    final caps = src.capabilities;

    _capsCacheForConfigId = id;
    _capsCache = caps;
    return caps;
  }

  /// ✅ 兼容旧名字：全项目只允许存在一次
  SourceCapabilities get currentWallpaperSourceCapabilities => currentCapabilities;

  ThemeStore() {
    final def = _registry.defaultConfig();
    _sourceConfigs = [def];
    _currentConfig = def;
    _loadFromPrefs();
  }

  void _recomputeEffectiveMode() {
    if (_enableCustomColors) {
      _mode = ThemeMode.light;
      return;
    }
    _mode = _enableThemeMode ? _preferredMode : ThemeMode.system;
  }

  // ===== Theme actions =====
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

  void setEnableCustomColors(bool value) {
    if (_enableCustomColors == value) return;
    _enableCustomColors = value;
    _recomputeEffectiveMode();
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

  // ===== Source actions =====
  bool _isBuiltIn(SourceConfig c) => c.id.startsWith('default_');

  void setCurrentSourceConfig(String configId) {
    if (_currentConfig.id == configId) return;
    final idx = _sourceConfigs.indexWhere((c) => c.id == configId);
    if (idx == -1) return;
    _currentConfig = _sourceConfigs[idx];
    _invalidateCapsCache();
    notifyListeners();
    savePreferences();
  }

  void addSource({
    required String pluginId,
    required String name,
    required Map<String, dynamic> settings,
  }) {
    final p = _registry.plugin(pluginId);
    if (p == null) throw StateError('Plugin not found: $pluginId');

    final cfg = SourceConfig(
      id: 'cfg_${DateTime.now().millisecondsSinceEpoch}',
      pluginId: pluginId,
      name: name.trim(),
      settings: p.sanitizeSettings(settings),
    );

    _sourceConfigs = [..._sourceConfigs, cfg];
    _invalidateCapsCache();
    notifyListeners();
    savePreferences();
  }

  void addSourceFromJson(Map<String, dynamic> json) {
    final pluginIdRaw = json['pluginId'];
    final String? pluginId =
        (pluginIdRaw is String && pluginIdRaw.trim().isNotEmpty) ? pluginIdRaw.trim() : null;

    final nameRaw = json['name'] ?? json['title'];
    final String name =
        (nameRaw is String && nameRaw.trim().isNotEmpty) ? nameRaw.trim() : '';

    if (pluginId != null) {
      final p = _registry.plugin(pluginId);
      if (p == null) {
        throw StateError('Plugin not found: $pluginId (registry 未注册该插件)');
      }

      final s = json['settings'];
      final Map<String, dynamic> settings = (s is Map) ? s.cast<String, dynamic>() : <String, dynamic>{};

      final finalName = name.isNotEmpty ? name : p.defaultName;

      addSource(pluginId: pluginId, name: finalName, settings: settings);
      return;
    }

    const genericId = 'generic';
    final p = _registry.plugin(genericId);
    if (p == null) {
      throw StateError('Generic plugin not found: $genericId（你必须在 SourceRegistry 注册 generic 插件）');
    }

    final finalName = name.isNotEmpty ? name : p.defaultName;

    addSource(
      pluginId: genericId,
      name: finalName,
      settings: json,
    );
  }

  void addSourceFromJsonString(String raw) {
    final text = raw.trim();
    if (text.isEmpty) throw FormatException('Empty json');
    final dynamic decoded = jsonDecode(text);
    if (decoded is! Map) throw FormatException('JSON must be an object');
    addSourceFromJson(decoded.cast<String, dynamic>());
  }

  void addWallhavenSource({
    required String name,
    required String url,
    String? username,
    String? apiKey,
  }) {
    addSource(
      pluginId: 'wallhaven',
      name: name,
      settings: {
        'baseUrl': url,
        'username': username,
        'apiKey': apiKey,
      },
    );
  }

  void updateSourceConfig(SourceConfig updated) {
    final idx = _sourceConfigs.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return;

    final p = _registry.plugin(updated.pluginId);
    if (p == null) return;

    final fixed = updated.copyWith(settings: p.sanitizeSettings(updated.settings));

    final next = [..._sourceConfigs];
    next[idx] = fixed;
    _sourceConfigs = next;

    if (_currentConfig.id == fixed.id) _currentConfig = fixed;

    _invalidateCapsCache();
    notifyListeners();
    savePreferences();
  }

  void removeSourceConfig(String id) {
    final idx = _sourceConfigs.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final target = _sourceConfigs[idx];
    if (_isBuiltIn(target)) return;

    final next = _sourceConfigs.where((c) => c.id != id).toList();
    if (next.isEmpty) return;

    _sourceConfigs = next;
    if (_currentConfig.id == id) _currentConfig = _sourceConfigs.first;

    _invalidateCapsCache();
    notifyListeners();
    savePreferences();
  }

  // ===== Persist =====
  Future<void> savePreferences() async {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 120), () async {
      final prefs = await SharedPreferences.getInstance();

      prefs.setInt('theme_mode', _preferredMode.index);
      prefs.setBool('enable_theme_mode', _enableThemeMode);

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

      prefs.setStringList(
        'source_configs',
        _sourceConfigs.map((c) => jsonEncode(c.toJson())).toList(),
      );
      prefs.setString('current_source_config_id', _currentConfig.id);
    });
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      _preferredMode = (modeIndex >= 0 && modeIndex < ThemeMode.values.length)
          ? ThemeMode.values[modeIndex]
          : ThemeMode.system;

      _enableThemeMode = prefs.getBool('enable_theme_mode') ?? true;

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

      final cfgJson = prefs.getStringList('source_configs');
      if (cfgJson != null && cfgJson.isNotEmpty) {
        final loaded = cfgJson
            .map((e) => SourceConfig.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .where((c) => c.id.isNotEmpty && c.pluginId.isNotEmpty)
            .toList();

        _sourceConfigs = loaded.isNotEmpty ? loaded : [_registry.defaultConfig()];
        final currentId = prefs.getString('current_source_config_id');

        _currentConfig = (currentId != null)
            ? _sourceConfigs.firstWhere((c) => c.id == currentId, orElse: () => _sourceConfigs.first)
            : _sourceConfigs.first;
      } else {
        final def = _registry.defaultConfig();
        _sourceConfigs = [def];
        _currentConfig = def;
      }

      // 全量清洗一次，避免历史脏数据
      _sourceConfigs = _sourceConfigs.map((c) {
        final p = _registry.plugin(c.pluginId);
        if (p == null) return c;
        return c.copyWith(settings: p.sanitizeSettings(c.settings));
      }).toList();

      final p = _registry.plugin(_currentConfig.pluginId);
      if (p != null) {
        _currentConfig = _currentConfig.copyWith(settings: p.sanitizeSettings(_currentConfig.settings));
      }

      _invalidateCapsCache();
      _recomputeEffectiveMode();
    } catch (e) {
      debugPrint("Load Prefs Error: $e");
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