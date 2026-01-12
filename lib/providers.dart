import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart';
import 'models/wallpaper.dart';

// === 全局常量：默认 App Headers ===
const Map<String, String> kDefaultAppHeaders = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
};

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

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
      ]
    ),
  ];

  int _currentSourceIndex = 0;
  Map<String, dynamic> _activeParams = {};
  List<Wallpaper> _favorites = [];

  List<SourceConfig> get sources => _sources;
  SourceConfig get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeParams => _activeParams;
  List<Wallpaper> get favorites => _favorites;
  
  // === ✨ 核心新增：获取合并后的 Headers ===
  // 将默认 Headers 与图源自定义 Headers 合并
  Map<String, String> getHeaders() {
    final Map<String, String> headers = Map.from(kDefaultAppHeaders);
    if (currentSource.headers != null) {
      headers.addAll(currentSource.headers!);
    }
    return headers;
  }

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

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
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
    
    String? savedFavs = _prefs?.getString('my_favorites_v1');
    if (savedFavs != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedFavs);
        _favorites = jsonList.map((e) => Wallpaper.fromJson(e)).toList();
      } catch (e) {
        debugPrint("收藏读取错误: $e");
      }
    }

    _loadFiltersForCurrentSource();
    notifyListeners();
  }

  void _loadFiltersForCurrentSource() {
    final key = "filters_${currentSource.baseUrl}";
    String? savedFilters = _prefs?.getString(key);
    if (savedFilters != null) {
      try {
        _activeParams = jsonDecode(savedFilters);
      } catch (e) {
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
    notifyListeners();
  }

  void _saveFavorites() {
    String jsonString = jsonEncode(_favorites.map((e) => e.toJson()).toList());
    _prefs?.setString('my_favorites_v1', jsonString);
  }

  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index);
    _loadFiltersForCurrentSource();
    notifyListeners();
  }

  void addSource(SourceConfig config) {
    _sources.add(config);
    _saveSourcesToDisk();
    notifyListeners();
  }

  void updateSource(int index, SourceConfig config) {
    if (index >= 0 && index < _sources.length) {
      _sources[index] = config;
      _saveSourcesToDisk();
      notifyListeners();
    }
  }

  void removeSource(int index) {
    if (_sources.length <= 1) return; 
    _sources.removeAt(index);
    if (_currentSourceIndex >= _sources.length) {
      _currentSourceIndex = 0;
    }
    _saveSourcesToDisk();
    _loadFiltersForCurrentSource();
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

  void updateParam(String key, dynamic value) {
    _activeParams[key] = value;
    _saveFiltersForCurrentSource(); 
    notifyListeners();
  }
  
  void updateSearchQuery(String q) {
    _activeParams['q'] = q;
    _saveFiltersForCurrentSource();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) { _themeMode = mode; _prefs?.setString('themeMode', mode.name); notifyListeners(); }
  void setMaterialYou(bool v) { _useMaterialYou = v; _prefs?.setBool('useMaterialYou', v); notifyListeners(); }
  void setAmoled(bool v) { _useAmoled = v; _prefs?.setBool('useAmoled', v); notifyListeners(); }
  void setLanguage(String v) { _locale = Locale(v); _prefs?.setString('language', v); notifyListeners(); }
  
  void setCornerRadius(double value) { _cornerRadius = value; _prefs?.setDouble('corner_radius', value); notifyListeners(); }
  void setHomeCornerRadius(double value) { _homeCornerRadius = value; _prefs?.setDouble('home_corner_radius', value); notifyListeners(); }

  void setCustomScaffoldColor(Color? color) {
    _customScaffoldColor = color;
    if (color == null) {
      _prefs?.remove('custom_scaffold_color');
    } else {
      _prefs?.setInt('custom_scaffold_color', color.value);
    }
    notifyListeners();
  }

  void setCustomCardColor(Color? color) {
    _customCardColor = color;
    if (color == null) {
      _prefs?.remove('custom_card_color');
    } else {
      _prefs?.setInt('custom_card_color', color.value);
    }
    notifyListeners();
  }
}
