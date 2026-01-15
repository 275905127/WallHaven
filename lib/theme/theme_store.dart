// lib/theme/theme_store.dart
import 'dart:async';
import 'dart:convert';
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
    if (scope == null) {
      throw FlutterError('ThemeScope not found in widget tree');
    }
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

  /// 插件私有配置（key/value）
  /// - Wallhaven: baseUrl, apiKey, username
  final Map<String, dynamic> settings;

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

  /// 默认展示名（不等于实例名，实例可改）
  String get defaultName;

  /// 生成一个默认实例配置（作为“内置默认源插件”）
  SourceConfig defaultConfig();

  /// ✅ 兼容层：把 SourceConfig 转回旧 ImageSource（仅用于过渡）
  ImageSource toLegacyImageSource(SourceConfig c);
}

/// Wallhaven 插件（默认插件）
/// - 注意：这里只是“描述+配置映射”，不是网络层
class WallhavenPlugin implements SourcePlugin {
  static const String kId = 'wallhaven';

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Wallhaven';

  static const String kDefaultBaseUrl = 'https://wallhaven.cc/api/v1';

  @override
  SourceConfig defaultConfig() {
    return SourceConfig(
      id: 'default_${WallhavenPlugin.kId}',
      pluginId: WallhavenPlugin.kId,
      name: defaultName,
      settings: const {
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
      driver: WallhavenPlugin.kId, // ✅ 必填
      apiKey: apiKey,
      username: username,
      // ✅ 只有默认实例算 built-in（否则用户添加的都算自定义）
      isBuiltIn: c.id == 'default_${WallhavenPlugin.kId}',
    );
  }

class SourceRegistry {
  final Map<String, SourcePlugin> _plugins;

  SourceRegistry._(this._plugins);

  factory SourceRegistry.defaultRegistry() {
    final plugins = <String, SourcePlugin>{
      WallhavenPlugin.kId: WallhavenPlugin(),
    };
    return SourceRegistry._(plugins);
  }

  SourcePlugin? plugin(String pluginId) => _plugins[pluginId];

  SourceConfig defaultConfig() {
    // 你以后可以改成：从某个“首选默认插件”里取
    return _plugins[WallhavenPlugin.kId]!.defaultConfig();
  }
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

  /// ✅ 兼容旧接口：给旧 UI / 旧调用链用（后续会删）
  List<ImageSource> get sources => _sourceConfigs.map(_toLegacy).toList();
  ImageSource get currentSource => _toLegacy(_currentConfig);

  ThemeStore() {
    // 默认先塞一个默认插件实例（避免启动空列表）
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
  // ✅ Source 新接口（插件化）
  // ======================

  void setCurrentSourceConfig(String configId) {
    if (_currentConfig.id == configId) return;
    final found = _sourceConfigs.where((c) => c.id == configId).toList();
    if (found.isEmpty) return;
    _currentConfig = found.first;
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

    // 基础清洗（只对 wallhaven 做：baseUrl/apiKey/username）
    var fixed = updated;
    if (updated.pluginId == WallhavenPlugin.kId) {
      final s = Map<String, dynamic>.from(updated.settings);
      final baseUrl = (s['baseUrl'] as String?) ?? WallhavenPlugin.kDefaultBaseUrl;
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
    // 默认插件实例不允许删（你真要删，也得先有其它源兜底）
    final isDefault = id == 'default_${WallhavenPlugin.kId}';
    if (isDefault) return;

    final next = _sourceConfigs.where((c) => c.id != id).toList();
    if (next.isEmpty) return;

    _sourceConfigs = next;
    if (_currentConfig.id == id) {
      _currentConfig = _sourceConfigs.first;
    }

    notifyListeners();
    savePreferences();
  }

  // ===================================
  // ✅ 旧接口兼容（别让其它文件现在就炸）
  // ===================================

  void setSource(ImageSource source) {
    // 老 UI 点选时会传 ImageSource，我们映射回 configId
    setCurrentSourceConfig(source.id);
  }

  void addSource(String name, String url, {String? username, String? apiKey}) {
    // 老 UI 添加：只能当成 wallhaven 风格源（过渡）
    addWallhavenSource(name: name, url: url, username: username, apiKey: apiKey);
  }

  void updateSource(ImageSource updatedSource) {
    // 老 UI 编辑：映射成 wallhaven config 更新（过渡）
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
      // 未知插件：给一个“空壳”避免崩
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

      // （可选）保留旧 keys 不写也行，但我不再维护旧 keys
    });
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ===== theme prefs =====
      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _preferredMode = ThemeMode.values[modeIndex];
      } else {
        _preferredMode = ThemeMode.system;
      }

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

        if (loaded.isNotEmpty) {
          _sourceConfigs = loaded;
        } else {
          _sourceConfigs = [_registry.defaultConfig()];
        }

        final currentId = prefs.getString('current_source_config_id');
        if (currentId != null) {
          _currentConfig = _sourceConfigs.firstWhere((c) => c.id == currentId, orElse: () => _sourceConfigs.first);
        } else {
          _currentConfig = _sourceConfigs.first;
        }
      } else {
        // ✅ 迁移旧：image_sources/current_source_id → source_configs/current_source_config_id
        final legacy = prefs.getStringList('image_sources');
        if (legacy != null && legacy.isNotEmpty) {
          final legacySources = legacy
              .map((e) => ImageSource.fromJson(jsonDecode(e) as Map<String, dynamic>))
              .where((s) => s.id.isNotEmpty && s.baseUrl.isNotEmpty)
              .toList();

          // 旧结构只有 wallhaven 风格：全部映射到 wallhaven 插件 config
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
          if (legacyCurrentId != null) {
            _currentConfig = _sourceConfigs.firstWhere((c) => c.id == legacyCurrentId, orElse: () => _sourceConfigs.first);
          } else {
            _currentConfig = _sourceConfigs.first;
          }

          // 写回新 key（一次迁移）
          prefs.setStringList('source_configs', _sourceConfigs.map((c) => jsonEncode(c.toJson())).toList());
          prefs.setString('current_source_config_id', _currentConfig.id);
        } else {
          // 完全没有：使用默认插件实例
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