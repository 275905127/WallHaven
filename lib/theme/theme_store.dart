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
// ThemeStore
// ----------------------------
class ThemeStore extends ChangeNotifier {
  // ⚠️ 这里只用于 currentCapabilities 的构造（会 new Dio），必须 dispose close。
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

  // ===== Source =====
  final SourceRegistry _registry = SourceRegistry.defaultRegistry();

  List<SourceConfig> _sourceConfigs = const [];
  late SourceConfig _currentConfig;

  // ===== Capabilities cache =====
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

  // ------------------------------------------------------------
  // Wallhaven baseUrl migration: ensure /api/v1
  // ------------------------------------------------------------
  Map<String, dynamic> _migrateWallhavenSettingsIfNeeded(
    String pluginId,
    Map<String, dynamic> sanitized,
  ) {
    if (pluginId != 'wallhaven') return sanitized;

    final next = Map<String, dynamic>.from(sanitized);

    String normWallhavenApiBase(String? raw) {
      var u = (raw ?? '').trim();
      if (u.isEmpty) u = 'https://wallhaven.cc';
      if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
      while (u.endsWith('/')) u = u.substring(0, u.length - 1);

      // ✅ force api root
      if (!u.endsWith('/api/v1')) u = '$u/api/v1';
      return u;
    }

    next['baseUrl'] = normWallhavenApiBase(next['baseUrl'] as String?);
    return next;
  }

  /// 给业务层用：拿到当前插件的“已清洗 settings”
  Map<String, dynamic> get currentSettings {
    final p = currentPlugin;
    final sanitized = p.sanitizeSettings(_currentConfig.settings);
    return _migrateWallhavenSettingsIfNeeded(_currentConfig.pluginId, sanitized);
  }

  /// 给 UI 用：当前 source capabilities（动态筛选 UI）
  SourceCapabilities get currentCapabilities {
    final id = _currentConfig.id;
    if (_capsCacheForConfigId == id && _capsCache != null) return _capsCache!;

    final src = _factory.fromStore(this);
    final caps = src.capabilities;

    _capsCacheForConfigId = id;
    _capsCache = caps;
    return caps;
  }

  /// 兼容旧名字
  SourceCapabilities get currentWallpaperSourceCapabilities => currentCapabilities;

  ThemeStore() {
    // ✅ 初始值：至少一个默认 config（由 registry 决定）
    final def = _registry.defaultConfig();
    final p = _registry.plugin(def.pluginId);

    final sanitized = (p != null)
        ? p.sanitizeSettings(def.settings)
        : Map<String, dynamic>.from(def.settings);

    final migrated = _migrateWallhavenSettingsIfNeeded(def.pluginId, sanitized);
    final fixedDef = def.copyWith(settings: migrated);

    _sourceConfigs = [fixedDef];
    _currentConfig = fixedDef;

    _loadFromPrefs();
  }

  // ------------------------------------------------------------
  // Theme mode recompute
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  // Source actions
  // ------------------------------------------------------------
  bool _isBuiltIn(SourceConfig c) => c.id.startsWith('default_');

  void setCurrentSourceConfig(String configId) {
    if (_currentConfig.id == configId) return;

    final idx = _sourceConfigs.indexWhere((c) => c.id == configId);
    if (idx == -1) return;

    final raw = _sourceConfigs[idx];
    final p = _registry.plugin(raw.pluginId);

    final sanitized = (p != null)
        ? p.sanitizeSettings(raw.settings)
        : Map<String, dynamic>.from(raw.settings);

    final migrated = _migrateWallhavenSettingsIfNeeded(raw.pluginId, sanitized);

    _currentConfig = raw.copyWith(settings: migrated);
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

    final sanitized = p.sanitizeSettings(settings);
    final migrated = _migrateWallhavenSettingsIfNeeded(pluginId, sanitized);

    final cfg = SourceConfig(
      id: 'cfg_${DateTime.now().millisecondsSinceEpoch}',
      pluginId: pluginId,
      name: name.trim(),
      settings: migrated,
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
      final Map<String, dynamic> settings =
          (s is Map) ? s.cast<String, dynamic>() : <String, dynamic>{};

      final finalName = name.isNotEmpty ? name : p.defaultName;
      addSource(pluginId: pluginId, name: finalName, settings: settings);
      return;
    }

    // 没给 pluginId -> 当作 generic 自由 JSON
    const genericId = 'generic';
    final p = _registry.plugin(genericId);
    if (p == null) {
      throw StateError('Generic plugin not found: $genericId（你必须在 SourceRegistry 注册 generic 插件）');
    }

    final finalName = name.isNotEmpty ? name : p.defaultName;
    addSource(pluginId: genericId, name: finalName, settings: json);
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

    final sanitized = p.sanitizeSettings(updated.settings);
    final migrated = _migrateWallhavenSettingsIfNeeded(updated.pluginId, sanitized);

    final fixed = updated.copyWith(settings: migrated);

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

  // ------------------------------------------------------------
  // Persist helpers: repair source configs
  // ------------------------------------------------------------
  List<SourceConfig> _repairSourceConfigs(List<SourceConfig> raw) {
    // 1) 先清洗 + 迁移
    final cleaned = raw.map((c) {
      final p = _registry.plugin(c.pluginId);
      if (p == null) return c;

      final sanitized = p.sanitizeSettings(c.settings);
      final migrated = _migrateWallhavenSettingsIfNeeded(c.pluginId, sanitized);
      return c.copyWith(settings: migrated);
    }).where((c) => c.id.isNotEmpty && c.pluginId.isNotEmpty).toList();

    // 2) 确保至少有一个默认 config（由 registry 决定）
    final def0 = _registry.defaultConfig();
    final defPlugin = _registry.plugin(def0.pluginId);
    final defSanitized = (defPlugin != null)
        ? defPlugin.sanitizeSettings(def0.settings)
        : Map<String, dynamic>.from(def0.settings);
    final defMigrated = _migrateWallhavenSettingsIfNeeded(def0.pluginId, defSanitized);
    final fixedDef = def0.copyWith(settings: defMigrated);

    // 3) 去掉重复 default（保留第一个）
    final out = <SourceConfig>[];
    var hasAnyDefault = false;

    for (final c in cleaned) {
      final isDef = c.id.startsWith('default_');
      if (isDef) {
        if (hasAnyDefault) continue; // drop duplicates
        hasAnyDefault = true;
      }
      out.add(c);
    }

    if (!hasAnyDefault) {
      out.insert(0, fixedDef);
    } else {
      // 如果已有 default，但 pluginId/结构怪异：用 registry 的 default 覆盖掉那个 default
      // ——避免历史坏默认把整个 app 锁死
      final idx = out.indexWhere((c) => c.id.startsWith('default_'));
      if (idx != -1) {
        out[idx] = fixedDef;
      }
    }

    return out;
  }

  // ------------------------------------------------------------
  // Persist
  // ------------------------------------------------------------
  Future<void> savePreferences() async {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 120), () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('theme_mode', _preferredMode.index);
      await prefs.setBool('enable_theme_mode', _enableThemeMode);

      await prefs.setInt('accent_color', _accentColor.toARGB32());
      await prefs.setString('accent_name', _accentName);

      await prefs.setBool('enable_custom_colors', _enableCustomColors);
      await prefs.setDouble('card_radius', _cardRadius);
      await prefs.setDouble('image_radius', _imageRadius);

      if (_customBackgroundColor != null) {
        await prefs.setInt('custom_bg_color', _customBackgroundColor!.toARGB32());
      } else {
        await prefs.remove('custom_bg_color');
      }

      if (_customCardColor != null) {
        await prefs.setInt('custom_card_color', _customCardColor!.toARGB32());
      } else {
        await prefs.remove('custom_card_color');
      }

      await prefs.setStringList(
        'source_configs',
        _sourceConfigs.map((c) => jsonEncode(c.toJson())).toList(),
      );
      await prefs.setString('current_source_config_id', _currentConfig.id);
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

      // ---- sources ----
      final cfgJson = prefs.getStringList('source_configs');
      List<SourceConfig> loaded = const [];

      if (cfgJson != null && cfgJson.isNotEmpty) {
        loaded = cfgJson
            .map((e) => SourceConfig.fromJson(jsonDecode(e) as Map<String, dynamic>))
            .toList();
      }

      _sourceConfigs = _repairSourceConfigs(loaded.isNotEmpty ? loaded : [_registry.defaultConfig()]);

      final wantedId = prefs.getString('current_source_config_id');
      if (wantedId != null && wantedId.trim().isNotEmpty) {
        _currentConfig = _sourceConfigs.firstWhere(
          (c) => c.id == wantedId,
          orElse: () => _sourceConfigs.first,
        );
      } else {
        _currentConfig = _sourceConfigs.first;
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
    _http.dio.close(force: true);
    super.dispose();
  }
}