import '../data/http/http_client.dart';
import '../data/source_factory.dart';
import '../domain/entities/source_capabilities.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sources/source_plugin.dart';
import '../sources/source_registry.dart';
import '../domain/entities/source_capabilities.dart';
import '../domain/entities/filter_spec.dart';
import '../domain/entities/option_item.dart';

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

class ThemeStore extends ChangeNotifier {
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
   
   SourceCapabilities get currentWallpaperSourceCapabilities {
  final pid = _currentConfig.pluginId;
  final s = currentSettings;

  if (pid == 'wallhaven') {
    // 和 WallhavenSource.capabilities 保持一致
    return const SourceCapabilities(
      supportsText: true,
      supportsSort: true,
      sortByOptions: [
        SortBy.toplist,
        SortBy.newest,
        SortBy.favorites,
        SortBy.views,
        SortBy.random,
        SortBy.relevance,
      ],
      supportsOrder: true,
      supportsResolutions: true,
      resolutionOptions: [
        '1280x720','1366x768','1600x900','1920x1080','1920x1200','2560x1440','2560x1600',
        '3440x1440','3840x2160','1080x1920','1440x2560','2160x3840',
      ],
      supportsAtleast: true,
      atleastOptions: [
        '','1280x720','1600x900','1920x1080','2560x1440','3440x1440','3840x2160',
        '1080x1920','1440x2560','2160x3840',
      ],
      supportsRatios: true,
      ratioOptions: ['16x9','16x10','21x9','32x9','4x3','3x2','5x4','1x1','9x16','10x16'],
      supportsColor: true,
      colorOptions: [
        '000000','111111','222222','333333','444444','555555','666666','777777','888888','999999',
        'AAAAAA','BBBBBB','CCCCCC','DDDDDD','EEEEEE','FFFFFF','660000','006600','000066','663300','003366','660066',
      ],
      supportsRating: true,
      ratingOptions: [RatingLevel.safe, RatingLevel.questionable, RatingLevel.explicit],
      supportsCategories: true,
      categoryOptions: [
        OptionItem(id: 'general', label: '常规'),
        OptionItem(id: 'anime', label: '动漫'),
        OptionItem(id: 'people', label: '人物'),
      ],
      supportsTimeRange: true,
      timeRangeOptions: [
        OptionItem(id: '1d', label: '1 天'),
        OptionItem(id: '3d', label: '3 天'),
        OptionItem(id: '1w', label: '1 周'),
        OptionItem(id: '1M', label: '1 月'),
        OptionItem(id: '3M', label: '3 月'),
        OptionItem(id: '6M', label: '6 月'),
        OptionItem(id: '1y', label: '1 年'),
      ],
    );
  }

  if (pid == 'generic') {
    // 由 settings['capabilities'] 驱动；如果没配就最小集（只关键词）
    final caps = s['capabilities'];
    if (caps is Map<String, dynamic>) {
      // 这里不重复写解析逻辑：最简单是让 GenericJsonSource 自己解析。
      // 但 ThemeStore 不应该依赖 data 层，所以做“保守返回”：
      // 只要你配置了 supportsX = true，就让 UI 展示；options 也从配置取。
      bool b(String k, bool def) => (caps[k] is bool) ? caps[k] as bool : def;

      List<String> strList(String k) {
        final v = caps[k];
        if (v is List) return v.map((e) => e?.toString() ?? '').where((e) => e.trim().isNotEmpty).toList();
        return const [];
      }

      List<OptionItem> optList(String k) {
        final v = caps[k];
        if (v is! List) return const [];
        final out = <OptionItem>[];
        for (final e in v) {
          if (e is Map) {
            final mm = (e as Map).cast<String, dynamic>();
            final id = (mm['id'] ?? '').toString().trim();
            final label = (mm['label'] ?? '').toString().trim();
            if (id.isNotEmpty && label.isNotEmpty) out.add(OptionItem(id: id, label: label));
          }
        }
        return out;
      }

      List<SortBy> sortList() {
        final raw = strList('sortByOptions');
        final out = <SortBy>[];
        for (final s in raw) {
          for (final e in SortBy.values) {
            if (e.name == s) out.add(e);
          }
        }
        return out;
      }

      List<RatingLevel> ratingList() {
        final raw = strList('ratingOptions');
        final out = <RatingLevel>[];
        for (final s in raw) {
          for (final e in RatingLevel.values) {
            if (e.name == s) out.add(e);
          }
        }
        return out;
      }

      return SourceCapabilities(
        supportsText: b('supportsText', true),
        supportsSort: b('supportsSort', false),
        sortByOptions: sortList(),
        supportsOrder: b('supportsOrder', false),
        supportsResolutions: b('supportsResolutions', false),
        resolutionOptions: strList('resolutionOptions'),
        supportsAtleast: b('supportsAtleast', false),
        atleastOptions: strList('atleastOptions'),
        supportsRatios: b('supportsRatios', false),
        ratioOptions: strList('ratioOptions'),
        supportsColor: b('supportsColor', false),
        colorOptions: strList('colorOptions'),
        supportsRating: b('supportsRating', false),
        ratingOptions: ratingList(),
        supportsCategories: b('supportsCategories', false),
        categoryOptions: optList('categoryOptions'),
        supportsTimeRange: b('supportsTimeRange', false),
        timeRangeOptions: optList('timeRangeOptions'),
      );
    }

    return const SourceCapabilities(
      supportsText: true,
      supportsSort: false,
      supportsOrder: false,
      supportsResolutions: false,
      supportsAtleast: false,
      supportsRatios: false,
      supportsColor: false,
      supportsRating: false,
      supportsCategories: false,
      supportsTimeRange: false,
    );
  }

  // 其他源：保守最小集
  return const SourceCapabilities(supportsText: true);
}
  /// 给业务层用：拿到当前插件的“已清洗 settings”
  Map<String, dynamic> get currentSettings => currentPlugin.sanitizeSettings(_currentConfig.settings);

  // ✅ 给 UI 用：当前 source 的 capabilities（用于动态筛选 UI）
  SourceCapabilities get currentWallpaperSourceCapabilities {
  // 这里不做全局 DI，就用一个共享 HttpClient
  // 只用于生成 source（不在这里发请求）
    final http = HttpClient();
    final factory = SourceFactory(http: http);
    final src = factory.fromStore(this);
    return src.capabilities;
  }

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
    notifyListeners();
    savePreferences();
  }

  /// ✅ 新增：从 JSON Map 添加“自由图源”
  ///
  /// 约定兼容两种格式：
  /// 1) 你贴的自由图源 JSON（无 pluginId）： { name, baseUrl, listKey, filters, ... }
  ///    -> 归入 pluginId = "generic"（你必须在 registry 里注册 generic 插件）
  /// 2) 完整插件化配置： { pluginId, name, settings: {...} }
  void addSourceFromJson(Map<String, dynamic> json) {
    // 允许用户粘贴“自由图源 JSON”
    final pluginIdRaw = json['pluginId'];
    final String? pluginId = (pluginIdRaw is String && pluginIdRaw.trim().isNotEmpty) ? pluginIdRaw.trim() : null;

    // 允许两种字段名：name / title
    final nameRaw = json['name'] ?? json['title'];
    final String name = (nameRaw is String && nameRaw.trim().isNotEmpty) ? nameRaw.trim() : '';

    if (pluginId != null) {
      // 走“完整插件化”
      final p = _registry.plugin(pluginId);
      if (p == null) {
        throw StateError('Plugin not found: $pluginId (registry 未注册该插件)');
      }

      final s = json['settings'];
      final Map<String, dynamic> settings =
          (s is Map) ? s.cast<String, dynamic>() : <String, dynamic>{};

      final finalName = name.isNotEmpty ? name : p.defaultName;

      addSource(
        pluginId: pluginId,
        name: finalName,
        settings: settings,
      );
      return;
    }

    // 没写 pluginId：按“自由图源”处理 -> generic 插件
    const genericId = 'generic';
    final p = _registry.plugin(genericId);
    if (p == null) {
      throw StateError('Generic plugin not found: $genericId（你必须在 SourceRegistry 注册 generic 插件）');
    }

    // 把自由图源 JSON 整体作为 settings 存进去（让 generic 插件自己解释）
    final finalName = name.isNotEmpty ? name : p.defaultName;

    addSource(
      pluginId: genericId,
      name: finalName,
      settings: json,
    );
  }

  /// ✅ 新增：从 JSON 字符串添加（UI 直接调用这个）
  void addSourceFromJsonString(String raw) {
    final text = raw.trim();
    if (text.isEmpty) throw FormatException('Empty json');
    final dynamic decoded = jsonDecode(text);
    if (decoded is! Map) throw FormatException('JSON must be an object');
    addSourceFromJson(decoded.cast<String, dynamic>());
  }

  /// 你现有 UI 的 “添加图源” 还是 wallhaven 参数，这里给它直接用
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

    notifyListeners();
    savePreferences();
  }

  void removeSourceConfig(String id) {
    final idx = _sourceConfigs.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final target = _sourceConfigs[idx];
    if (_isBuiltIn(target)) return; // 默认实例不允许删

    final next = _sourceConfigs.where((c) => c.id != id).toList();
    if (next.isEmpty) return;

    _sourceConfigs = next;
    if (_currentConfig.id == id) _currentConfig = _sourceConfigs.first;

    notifyListeners();
    savePreferences();
  }

  // ===== 持久化 =====

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
      _preferredMode =
          (modeIndex >= 0 && modeIndex < ThemeMode.values.length) ? ThemeMode.values[modeIndex] : ThemeMode.system;

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