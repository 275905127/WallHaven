// lib/providers.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart';
import 'models/wallpaper.dart';
import 'package:http/http.dart' as http;

// === 全局常量：统一 User-Agent ===
const Map<String, String> kAppHeaders = {
  "User-Agent":
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
};

// === 备份键 ===
const String kBackupKey = 'app_backup_v1';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // ============================================================
// ☁️ 从云端 URL 恢复【完整备份】
// ============================================================
Future<bool> importBackupFromUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    final resp = await http.get(uri, headers: kAppHeaders);

    if (resp.statusCode != 200) return false;

    final jsonString = resp.body;
    return await importBackupJson(jsonString);
  } catch (e) {
    debugPrint("importBackupFromUrl failed: $e");
    return false;
  }
}

// ============================================================
// ☁️ 从云端 URL 导入【单个图源 SourceConfig】
// ============================================================
Future<bool> importSourceFromUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    final resp = await http.get(uri, headers: kAppHeaders);

    if (resp.statusCode != 200) return false;

    final jsonString = resp.body;
    return importSourceConfig(jsonString);
  } catch (e) {
    debugPrint("importSourceFromUrl failed: $e");
    return false;
  }
} 

  // 默认图源 - Wallhaven
  List<SourceConfig> _sources = [
    SourceConfig(
      name: 'Wallhaven',
      baseUrl: 'https://wallhaven.cc/api/v1/search',
      filters: [
        FilterGroup(title: '分类 (Categories)', paramName: 'categories', type: 'bitmask', options: [
          FilterOption(label: '常规', value: 'General'),
          FilterOption(label: '动漫', value: 'Anime'),
          FilterOption(label: '人物', value: 'People'),
        ]),
        FilterGroup(title: '分级 (Purity)', paramName: 'purity', type: 'bitmask', options: [
          FilterOption(label: 'SFW', value: 'SFW'),
          FilterOption(label: 'Sketchy', value: 'Sketchy'),
          FilterOption(label: 'NSFW', value: 'NSFW'),
        ]),
        FilterGroup(title: '排序 (Sorting)', paramName: 'sorting', type: 'radio', options: [
          FilterOption(label: '最新', value: 'date_added'),
          FilterOption(label: '相关', value: 'relevance'),
          FilterOption(label: '随机', value: 'random'),
          FilterOption(label: '浏览', value: 'views'),
          FilterOption(label: '收藏', value: 'favorites'),
          FilterOption(label: '排行', value: 'toplist'),
        ]),
        FilterGroup(title: '顺序 (Order)', paramName: 'order', type: 'radio', options: [
          FilterOption(label: '降序', value: 'desc'),
          FilterOption(label: '升序', value: 'asc'),
        ]),
        FilterGroup(title: '排行榜范围 (Top Range)', paramName: 'topRange', type: 'radio', options: [
          FilterOption(label: '1天', value: '1d'),
          FilterOption(label: '3天', value: '3d'),
          FilterOption(label: '1周', value: '1w'),
          FilterOption(label: '1月', value: '1M'),
          FilterOption(label: '3月', value: '3M'),
          FilterOption(label: '6月', value: '6M'),
          FilterOption(label: '1年', value: '1y'),
        ]),
        FilterGroup(title: '分辨率 (At Least)', paramName: 'atleast', type: 'radio', options: [
          FilterOption(label: '任意', value: ''),
          FilterOption(label: '1920x1080', value: '1920x1080'),
          FilterOption(label: '2560x1440', value: '2560x1440'),
          FilterOption(label: '3840x2160 (4K)', value: '3840x2160'),
        ]),
        FilterGroup(title: '比例 (Ratios)', paramName: 'ratios', type: 'radio', options: [
          FilterOption(label: '任意', value: ''),
          FilterOption(label: '横屏', value: 'landscape'),
          FilterOption(label: '竖屏', value: 'portrait'),
          FilterOption(label: '16:9', value: '16x9'),
          FilterOption(label: '16:10', value: '16x10'),
          FilterOption(label: '21:9', value: '21x9'),
          FilterOption(label: '9:16', value: '9x16'),
        ]),
      ],
    ),
  ];

  int _currentSourceIndex = 0;
  Map<String, dynamic> _activeParams = {};

  // 收藏
  List<Wallpaper> _favorites = [];

  List<SourceConfig> get sources => _sources;
  SourceConfig get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeParams => _activeParams;
  List<Wallpaper> get favorites => _favorites;

  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterialYou = true;
  bool _useAmoled = false;
  Locale _locale = const Locale('zh');

  double _cornerRadius = 24.0;
  double _homeCornerRadius = 12.0;

  Color? _customScaffoldColor;
  Color? _customCardColor;

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  bool get useAmoled => _useAmoled;
  Locale get locale => _locale;
  double get cornerRadius => _cornerRadius;
  double get homeCornerRadius => _homeCornerRadius;

  Color? get customScaffoldColor => _customScaffoldColor;
  Color? get customCardColor => _customCardColor;

  // === 备份节流 ===
  DateTime _lastBackupWrite = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 1) 外观
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;

    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;

    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);

    _cornerRadius = _prefs?.getDouble('corner_radius') ?? 24.0;
    _homeCornerRadius = _prefs?.getDouble('home_corner_radius') ?? 12.0;

    int? scaffoldColorVal = _prefs?.getInt('custom_scaffold_color');
    if (scaffoldColorVal != null) _customScaffoldColor = Color(scaffoldColorVal);

    int? cardColorVal = _prefs?.getInt('custom_card_color');
    if (cardColorVal != null) _customCardColor = Color(cardColorVal);

    // 2) 图源
    String? savedSources = _prefs?.getString('generic_sources_v2');
    if (savedSources != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedSources);
        if (jsonList.isNotEmpty) {
          _sources = jsonList.map((e) => SourceConfig.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint("图源读取错误: $e");
      }
    }

    _currentSourceIndex = _prefs?.getInt('current_source_index') ?? 0;
    if (_currentSourceIndex >= _sources.length) _currentSourceIndex = 0;

    // 3) 收藏
    String? savedFavs = _prefs?.getString('my_favorites_v1');
    if (savedFavs != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedFavs);
        _favorites = jsonList.map((e) => Wallpaper.fromJson(e)).toList();
      } catch (e) {
        debugPrint("收藏读取错误: $e");
      }
    }

    // 4) 当前源筛选
    _loadFiltersForCurrentSource();

    notifyListeners();
  }

  // === 每源筛选持久化 ===
  void _loadFiltersForCurrentSource() {
    final key = "filters_${currentSource.baseUrl}";
    String? savedFilters = _prefs?.getString(key);
    if (savedFilters != null) {
      try {
        _activeParams = jsonDecode(savedFilters);
      } catch (_) {
        _activeParams = {};
      }
    } else {
      _activeParams = {};
    }
  }

  void _saveFiltersForCurrentSource() {
    final key = "filters_${currentSource.baseUrl}";
    _prefs?.setString(key, jsonEncode(_activeParams));
  }

  // === 收藏 ===
  bool isFavorite(Wallpaper wallpaper) {
    return _favorites.any((e) => e.id == wallpaper.id);
  }

  void toggleFavorite(Wallpaper wallpaper) {
    if (isFavorite(wallpaper)) {
      _favorites.removeWhere((e) => e.id == wallpaper.id);
    } else {
      _favorites.add(wallpaper);
    }
    _saveFavorites();
    _autoBackup();
    notifyListeners();
  }

  void _saveFavorites() {
    String jsonString = jsonEncode(_favorites.map((e) => e.toJson()).toList());
    _prefs?.setString('my_favorites_v1', jsonString);
  }

  // === 图源管理 ===
  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index);
    _loadFiltersForCurrentSource();
    _autoBackup();
    notifyListeners();
  }

  void addSource(SourceConfig config) {
    _sources.add(config);
    _saveSourcesToDisk();
    _autoBackup();
    notifyListeners();
  }

  void updateSource(int index, SourceConfig config) {
    if (index >= 0 && index < _sources.length) {
      _sources[index] = config;
      _saveSourcesToDisk();
      _autoBackup();
      notifyListeners();
    }
  }

  void removeSource(int index) {
    if (_sources.length <= 1) return;

    // 删源前也备一份
    _autoBackup(force: true);

    final removed = _sources[index].baseUrl;
    _sources.removeAt(index);

    if (_currentSourceIndex >= _sources.length) {
      _currentSourceIndex = 0;
    }

    _saveSourcesToDisk();
    _prefs?.remove("filters_$removed"); // 顺手清它自己的筛选缓存
    _loadFiltersForCurrentSource();
    _autoBackup();
    notifyListeners();
  }

  bool importSourceConfig(String jsonString) {
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final config = SourceConfig.fromJson(map);
      addSource(config);
      return true;
    } catch (e) {
      debugPrint("导入失败: $e");
      return false;
    }
  }

  void _saveSourcesToDisk() {
    String jsonString = jsonEncode(_sources.map((e) => e.toJson()).toList());
    _prefs?.setString('generic_sources_v2', jsonString);
  }

  // === 参数更新 ===
  void updateParam(String key, dynamic value) {
    _activeParams[key] = value;
    _saveFiltersForCurrentSource();
    _autoBackup();
    notifyListeners();
  }

  void updateSearchQuery(String q) {
    _activeParams['q'] = q;
    _saveFiltersForCurrentSource();
    _autoBackup();
    notifyListeners();
  }

  // === 外观设置 ===
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    _autoBackup();
    notifyListeners();
  }

  void setMaterialYou(bool v) {
    _useMaterialYou = v;
    _prefs?.setBool('useMaterialYou', v);
    _autoBackup();
    notifyListeners();
  }

  void setAmoled(bool v) {
    _useAmoled = v;
    _prefs?.setBool('useAmoled', v);
    _autoBackup();
    notifyListeners();
  }

  void setLanguage(String v) {
    _locale = Locale(v);
    _prefs?.setString('language', v);
    _autoBackup();
    notifyListeners();
  }

  void setCornerRadius(double value) {
    _cornerRadius = value;
    _prefs?.setDouble('corner_radius', value);
    _autoBackup();
    notifyListeners();
  }

  void setHomeCornerRadius(double value) {
    _homeCornerRadius = value;
    _prefs?.setDouble('home_corner_radius', value);
    _autoBackup();
    notifyListeners();
  }

  void setCustomScaffoldColor(Color? color) {
    _customScaffoldColor = color;
    if (color == null) {
      _prefs?.remove('custom_scaffold_color');
    } else {
      _prefs?.setInt('custom_scaffold_color', color.value);
    }
    _autoBackup();
    notifyListeners();
  }

  void setCustomCardColor(Color? color) {
    _customCardColor = color;
    if (color == null) {
      _prefs?.remove('custom_card_color');
    } else {
      _prefs?.setInt('custom_card_color', color.value);
    }
    _autoBackup();
    notifyListeners();
  }

  // ============================================================
  // ✅ 备份/恢复（全量：源 + 每源筛选 + 收藏 + 外观）
  // ============================================================

  /// 导出备份 JSON（给 Settings 页复制用）
  String exportBackupJson() {
    final map = _buildBackupMap();
    return jsonEncode(map);
  }

  /// 导入备份 JSON（写回 prefs + 重载内存）
  Future<bool> importBackupJson(String jsonString) async {
    if (_prefs == null) return false;

    try {
      final dynamic raw = jsonDecode(jsonString);
      if (raw is! Map) return false;

      final int version = (raw['version'] as num?)?.toInt() ?? 1;

      // 1) sources
      final sourcesRaw = raw['sources'];
      if (sourcesRaw is List) {
        final sourcesJson = jsonEncode(sourcesRaw);
        await _prefs!.setString('generic_sources_v2', sourcesJson);
      }

      // 2) current index
      final idx = (raw['current_source_index'] as num?)?.toInt();
      if (idx != null) {
        await _prefs!.setInt('current_source_index', idx);
      }

      // 3) favorites
      final favsRaw = raw['favorites'];
      if (favsRaw is List) {
        await _prefs!.setString('my_favorites_v1', jsonEncode(favsRaw));
      }

      // 4) appearance
      final app = raw['appearance'];
      if (app is Map) {
        final themeMode = app['themeMode']?.toString();
        if (themeMode != null) await _prefs!.setString('themeMode', themeMode);

        final useMY = app['useMaterialYou'];
        if (useMY is bool) await _prefs!.setBool('useMaterialYou', useMY);

        final useAmoled = app['useAmoled'];
        if (useAmoled is bool) await _prefs!.setBool('useAmoled', useAmoled);

        final language = app['language']?.toString();
        if (language != null) await _prefs!.setString('language', language);

        final cr = app['corner_radius'];
        if (cr is num) await _prefs!.setDouble('corner_radius', cr.toDouble());

        final hr = app['home_corner_radius'];
        if (hr is num) await _prefs!.setDouble('home_corner_radius', hr.toDouble());

        final sc = app['custom_scaffold_color'];
        if (sc == null) {
          await _prefs!.remove('custom_scaffold_color');
        } else if (sc is num) {
          await _prefs!.setInt('custom_scaffold_color', sc.toInt());
        }

        final cc = app['custom_card_color'];
        if (cc == null) {
          await _prefs!.remove('custom_card_color');
        } else if (cc is num) {
          await _prefs!.setInt('custom_card_color', cc.toInt());
        }
      }

      // 5) filters_by_source
      final fbs = raw['filters_by_source'];
      if (fbs is Map) {
        for (final entry in fbs.entries) {
          final baseUrl = entry.key.toString();
          final v = entry.value;
          if (v is Map || v is List) {
            await _prefs!.setString("filters_$baseUrl", jsonEncode(v));
          } else if (v is String) {
            // 容错：如果旧备份存的是字符串
            await _prefs!.setString("filters_$baseUrl", v);
          }
        }
      }

      // 6) 把备份本体也存一份（方便以后“恢复到上次自动备份”）
      await _prefs!.setString(kBackupKey, jsonEncode(raw));

      // 7) 重载内存状态
      await init();

      debugPrint("Backup imported. version=$version");
      return true;
    } catch (e) {
      debugPrint("importBackupJson failed: $e");
      return false;
    }
  }

  /// 读取“上次自动备份”的 JSON（没有就空）
  String? getLastBackupJson() {
    return _prefs?.getString(kBackupKey);
  }

  // === 内部：构建备份结构 ===
  Map<String, dynamic> _buildBackupMap() {
    final filtersBySource = <String, dynamic>{};
    for (final s in _sources) {
      final key = "filters_${s.baseUrl}";
      final raw = _prefs?.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          filtersBySource[s.baseUrl] = jsonDecode(raw);
        } catch (_) {
          filtersBySource[s.baseUrl] = raw; // 容错：存原字符串
        }
      } else {
        filtersBySource[s.baseUrl] = {}; // 没有就空
      }
    }

    final appearance = <String, dynamic>{
      'themeMode': _themeMode.name,
      'useMaterialYou': _useMaterialYou,
      'useAmoled': _useAmoled,
      'language': _locale.languageCode,
      'corner_radius': _cornerRadius,
      'home_corner_radius': _homeCornerRadius,
      'custom_scaffold_color': _customScaffoldColor?.value,
      'custom_card_color': _customCardColor?.value,
    };

    return {
      'version': 1,
      'ts': DateTime.now().toIso8601String(),
      'current_source_index': _currentSourceIndex,
      'sources': _sources.map((e) => e.toJson()).toList(),
      'filters_by_source': filtersBySource,
      'favorites': _favorites.map((e) => e.toJson()).toList(),
      'appearance': appearance,
    };
  }

  // === 自动备份：任何变更点都会写，但有节流 ===
  void _autoBackup({bool force = false}) {
    if (_prefs == null) return;

    final now = DateTime.now();
    if (!force && now.difference(_lastBackupWrite).inMilliseconds < 900) {
      return;
    }
    _lastBackupWrite = now;

    try {
      final map = _buildBackupMap();
      _prefs!.setString(kBackupKey, jsonEncode(map));
    } catch (e) {
      debugPrint("_autoBackup failed: $e");
    }
  }
}