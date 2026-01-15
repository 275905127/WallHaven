// lib/theme/theme_store.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/image_source.dart';

// ✅ ThemeScope：不再 new 影子 store
class ThemeScope extends InheritedWidget {
  final ThemeStore store;
  const ThemeScope({super.key, required this.store, required super.child});

  static ThemeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found in widget tree');
    if (scope == null) throw FlutterError('ThemeScope not found in widget tree');
    return scope.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => !identical(store, oldWidget.store);
}

/// ===============================
/// ✅ 插件化：SourceConfig + Registry
/// ===============================

@immutable
class SourceConfig {
  final String id; // 实例 id
  final String pluginId; // 插件 id（wallhaven / 自定义插件…）
  final String name; // 展示名
  final Map<String, dynamic> settings; // 插件私有配置

  const SourceConfig({
    required this.id,
    required this.pluginId,
    required this.name,
    required this.settings,
  });

  SourceConfig copyWith({
    String? name,
    Map<String, dynamic>? settings,
  }) {
    return SourceConfig(
      id: id,
      pluginId: pluginId,
      name: name ?? this.name,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pluginId': pluginId,
        'name': name,
        'settings': settings,
      };

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      id: (json['id'] as String?) ?? '',
      pluginId: (json['pluginId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      settings: (json['settings'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }
}

abstract class SourcePlugin {
  String get pluginId;
  String get defaultName;
  SourceConfig defaultConfig();

  /// ✅ 兼容层：把 SourceConfig 转回旧 ImageSource（仅用于过渡）
  ImageSource toLegacyImageSource(SourceConfig c);
}

/// Wallhaven 插件（默认插件）
/// - 注意：这里只是“描述+配置映射”，不是网络层
class WallhavenPlugin implements SourcePlugin {
  static const String kId = 'wallhaven';
  static const String kDefaultBaseUrl = 'https://wallhaven.cc/api/v1';

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Wallhaven';

  @override
  SourceConfig defaultConfig() {
    return const SourceConfig(
      id: 'default_wallhaven',
      pluginId: WallhavenPlugin.kId,
      name: 'Wallhaven',
      settings: {
        'baseUrl': kDefaultBaseUrl,
        'apiKey': null,
        'username': null,
      },
    );
  }

  @override
  ImageSource toLegacyImageSource(SourceConfig c) {
    final baseUrl = (c.settings['baseUrl'] as String?) ?? kDefaultBaseUrl;
    final apiKey = c.settings['apiKey'] as String?;
    final username = c.settings['username'] as String?;
    return ImageSource(
      id: c.id,
      name: c.name,
      baseUrl: baseUrl,
      apiKey: apiKey,
      username: username,
      // ✅ 只有默认实例算 built-in（否则用户添加的都算自定义）
      isBuiltIn: c.id == 'default_wallhaven',
    );
  }
}

class SourceRegistry {
  final Map<String, SourcePlugin> _plugins;
  SourceRegistry._(this._plugins);

  factory SourceRegistry.defaultRegistry() {
    return SourceRegistry._({
      WallhavenPlugin.kId: WallhavenPlugin(),
    });
  }

  SourcePlugin? plugin(String pluginId) => _plugins[pluginId];

  SourceConfig defaultConfig() => _plugins[WallhavenPlugin.kId]!.defaultConfig();
}

class ThemeStore extends ChangeNotifier {
  // ===== Theme（保持原逻辑）=====
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

  // ===== Source（插件化）=====
  final SourceRegistry _registry = SourceRegistry.defaultRegistry();

  List<SourceConfig> _sourceConfigs = const [];
  late SourceConfig _currentConfig;

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

  /// ✅ 新接口：当前源配置（插件实例）
  List<SourceConfig> get sourceConfigs => _sourceConfigs;
  SourceConfig get currentSourceConfig => _currentConfig;

  /// ✅ 给 main.dart / UI 快速取配置用
  SourcePlugin? get currentPlugin => _registry.plugin(_currentConfig.pluginId);
  Map<String, dynamic> get currentPluginSettings => _currentConfig.settings;

  /// ✅ 统一出口：当前源连接信息（只暴露 UI 需要的，不把网络塞进 store）
  /// - 未来你新增插件时，在这里按 pluginId 分支返回对应结构
  String get currentBaseUrl {
    if (_currentConfig.pluginId == WallhavenPlugin.kId) {
      final s = _currentConfig.settings;
      final raw = (s['baseUrl'] as String?)?.trim();
      return _normalizeBaseUrl(raw?.isNotEmpty == true ? raw! : WallhavenPlugin.kDefaultBaseUrl);
    }
    // 未知插件：返回空，调用点应该自己处理（并提示用户）
    return '';
  }

  String? get currentApiKey {
    final s = _currentConfig.settings;
    final raw = (s['apiKey'] as String?)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  String? get currentUsername {
    final s = _currentConfig.settings;
    final raw = (s['username'] as String?)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// ✅ 兼容旧接口：给旧 UI / 旧调用链用（后续会删）
  List<ImageSource> get sources => _sourceConfigs.map(_toLegacy).toList();
  ImageSource get currentSource => _toLegacy(_currentConfig);

  ThemeStore() {
    final def = _registry.defaultConfig();
    _sourceConfigs = [def];
    _currentConfig = def;
    _loadFromPrefs();
  }

  // ========= 规则：只能一个生效 =========
  void _recomputeEffectiveMode() {
    if (_enableCustomColors) {
      _mode = ThemeMode.light;
      return;
    }
    _mode = _enableThemeMode ? _preferredMode : ThemeMode.system;
  }

  // ===== Theme Actions（原样）=====
  void setPreferredMode(ThemeMode newMode) {
    if (_preferredMode == newMode) return;
    _preferredMode = newMode;
    _recomputeEffectiveMode();
    notifyListeners();
    savePreferences();
  }

  void setMode(ThemeMode newMode) => setPreferredMode(newMode);

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

  // ======================
  // ✅ Source Actions（插件化）
  // ======================

  void setCurrentSourceConfig(String configId) {
    if (_currentConfig.id == configId) return;
    final idx = _sourceConfigs.indexWhere((c) => c.id == configId);
    if (idx == -1) return;
    _currentConfig = _sourceConfigs[idx];
    notifyListeners();
    savePreferences();
  }

  void addWallhavenSource({
    required String name,
    required String url,
    String? username,
    String? apiKey,
  }) {
    final cfg = SourceConfig(
      id: 'cfg_${DateTime.now().millisecondsSinceEpoch}',
      pluginId: WallhavenPlugin.kId,
      name: name.trim(),
      settings: {
        'baseUrl': _normalizeBaseUrl(url),
        'username': _normalizeOptional(username),
        'apiKey': _normalizeOptional(apiKey),
      },
    );
    _sourceConfigs = [..._sourceConfigs, cfg];
    notifyListeners();
    savePreferences();
  }

  void updateSourceConfig(SourceConfig updated) {
    final idx = _sourceConfigs.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return;

    var fixed = updated;

    // ✅ 基础清洗：按插件分发（目前只有 wallhaven）
    if (updated.pluginId == WallhavenPlugin.kId) {
      final s = Map<String, dynamic>.from(updated.settings);
      final rawBase = (s['baseUrl'] as String?)?.trim();
      final baseUrl = (rawBase != null && rawBase.isNotEmpty) ? rawBase : WallhavenPlugin.kDefaultBaseUrl;
      s['baseUrl'] = _normalizeBaseUrl(baseUrl);
      s['username'] = _normalizeOptional(s['username'] as String?);
      s['apiKey'] = _normalizeOptional(s['apiKey'] as String?);
      fixed = updated.copyWith(settings: s);
    }

    final next = [..._sourceConfigs];
    next[idx] = fixed;
    _sourceConfigs = next;

    if (_currentConfig.id == fixed.id) _currentConfig = fixed;

    notifyListeners();
    savePreferences();
  }

  void removeSourceConfig(String id) {
    // 默认插件实例不允许删
    final isDefault = id == 'default_wallhaven';
    if (isDefault) return;

    final next = _sourceConfigs.where((c) => c.id != id).toList();
    if (next.isEmpty) return;

    _sourceConfigs = next;
    if (_currentConfig.id == id) _currentConfig = _sourceConfigs.first;

    notifyListeners();
    savePreferences();
  }

  // ===================================
  // ✅ 旧接口兼容（别让其它文件现在就炸）
  // ===================================

  void setSource(ImageSource source) => setCurrentSourceConfig(source.id);

  void addSource(String name, String url, {String? username, String? apiKey}) {
    addWallhavenSource(name: name, url: url, username: username, apiKey: apiKey);
  }

  void updateSource(ImageSource updatedSource) {
    final cfg = SourceConfig(
      id: updatedSource.id,
      pluginId: WallhavenPlugin.kId,
      name: updatedSource.name,
      settings: {
        'baseUrl': updatedSource.baseUrl,
        'username': updatedSource.username,
        'apiKey': updatedSource.apiKey,
      },
    );
    updateSourceConfig(cfg);
  }

  void removeSource(String id) => removeSourceConfig(id);

  ImageSource _toLegacy(SourceConfig c) {
    final p = _registry.plugin(c.pluginId);
    if (p == null) {
      return ImageSource(
        id: c.id,
        name: c.name,
        baseUrl: (c.settings['baseUrl'] as String?) ?? '',
        apiKey: (c.settings['apiKey'] as String?),
        username: (c.settings['username'] as String?),
        isBuiltIn: false,
      );
    }
    return p.toLegacyImageSource(c);
  }

  // ========= 持久化 =========

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

      // ✅ 新 keys（插件化）
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

      // ===== theme prefs =====
      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      _preferredMode = (modeIndex >= 0 && modeIndex < ThemeMode.values.length) ? ThemeMode.values[modeIndex] : ThemeMode.system;

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

      // ===== source prefs（新优先；没有则迁移旧）=====
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

        // ✅ 防御：把 wallhaven baseUrl 再清洗一遍，防止脏数据导致请求炸
        _sourceConfigs = _sourceConfigs.map((c) {
          if (c.pluginId != WallhavenPlugin.kId) return c;
          final s = Map<String, dynamic>.from(c.settings);
          final raw = (s['baseUrl'] as String?)?.trim();
          final baseUrl = (raw != null && raw.isNotEmpty) ? raw : WallhavenPlugin.kDefaultBaseUrl;
          s['baseUrl'] = _normalizeBaseUrl(baseUrl);
          s['username'] = _normalizeOptional(s['username'] as String?);
          s['apiKey'] = _normalizeOptional(s['apiKey'] as String?);
          return c.copyWith(settings: s);
        }).toList();

        _currentConfig = _sourceConfigs.firstWhere((c) => c.id == _currentConfig.id, orElse: () => _sourceConfigs.first);
      } else {
        // ✅ 迁移旧：image_sources/current_source_id → source_configs/current_source_config_id
        final legacy = prefs.getStringList('image_sources');

        if (legacy != null && legacy.isNotEmpty) {
          final legacySources = legacy
              .map((e) => ImageSource.fromJson(jsonDecode(e) as Map<String, dynamic>))
              .where((s) => s.id.isNotEmpty && s.baseUrl.isNotEmpty)
              .toList();

          final mapped = legacySources.map((s) {
            return SourceConfig(
              id: s.id,
              pluginId: WallhavenPlugin.kId,
              name: s.name,
              settings: {
                'baseUrl': _normalizeBaseUrl(s.baseUrl),
                'username': _normalizeOptional(s.username),
                'apiKey': _normalizeOptional(s.apiKey),
              },
            );
          }).toList();

          _sourceConfigs = mapped.isNotEmpty ? mapped : [_registry.defaultConfig()];

          final legacyCurrentId = prefs.getString('current_source_id');
          _currentConfig = (legacyCurrentId != null)
              ? _sourceConfigs.firstWhere((c) => c.id == legacyCurrentId, orElse: () => _sourceConfigs.first)
              : _sourceConfigs.first;

          // 写回新 key（一次迁移）
          await prefs.setStringList('source_configs', _sourceConfigs.map((c) => jsonEncode(c.toJson())).toList());
          await prefs.setString('current_source_config_id', _currentConfig.id);
        } else {
          final def = _registry.defaultConfig();
          _sourceConfigs = [def];
          _currentConfig = def;
        }
      }

      _recomputeEffectiveMode();
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