import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // 默认图源 - Wallhaven
  List<SourceConfig> _sources = [
    SourceConfig(
      name: 'Wallhaven',
      baseUrl: 'https://wallhaven.cc/api/v1/search',
      filters: [
        // 1. 分类 (Categories)
        FilterGroup(title: '分类 (Categories)', paramName: 'categories', type: 'bitmask', options: [
            FilterOption(label: '常规', value: 'General'),
            FilterOption(label: '动漫', value: 'Anime'),
            FilterOption(label: '人物', value: 'People'),
        ]),
        // 2. 分级 (Purity)
        FilterGroup(title: '分级 (Purity)', paramName: 'purity', type: 'bitmask', options: [
            FilterOption(label: 'SFW', value: 'SFW'),
            FilterOption(label: 'Sketchy', value: 'Sketchy'),
            FilterOption(label: 'NSFW', value: 'NSFW'),
        ]),
        // 3. 排序 (Sorting)
        FilterGroup(title: '排序 (Sorting)', paramName: 'sorting', type: 'radio', options: [
            FilterOption(label: '最新', value: 'date_added'),
            FilterOption(label: '相关', value: 'relevance'),
            FilterOption(label: '随机', value: 'random'),
            FilterOption(label: '浏览', value: 'views'),
            FilterOption(label: '收藏', value: 'favorites'),
            FilterOption(label: '排行', value: 'toplist'),
        ]),
        // 4. 顺序 (Order)
        FilterGroup(title: '顺序 (Order)', paramName: 'order', type: 'radio', options: [
            FilterOption(label: '降序', value: 'desc'),
            FilterOption(label: '升序', value: 'asc'),
        ]),
        // 5. 排行榜时间范围 (Toplist Range) - 仅在排序为 Toplist 时有效
        FilterGroup(title: '排行榜范围 (Top Range)', paramName: 'topRange', type: 'radio', options: [
            FilterOption(label: '1天', value: '1d'),
            FilterOption(label: '3天', value: '3d'),
            FilterOption(label: '1周', value: '1w'),
            FilterOption(label: '1月', value: '1M'),
            FilterOption(label: '3月', value: '3M'),
            FilterOption(label: '6月', value: '6M'),
            FilterOption(label: '1年', value: '1y'),
        ]),
        // 6. 分辨率 (Resolution)
        FilterGroup(title: '分辨率 (At Least)', paramName: 'atleast', type: 'radio', options: [
            FilterOption(label: '任意', value: ''),
            FilterOption(label: '1920x1080', value: '1920x1080'),
            FilterOption(label: '2560x1440', value: '2560x1440'),
            FilterOption(label: '3840x2160 (4K)', value: '3840x2160'),
        ]),
        // 7. 比例 (Ratios)
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

  List<SourceConfig> get sources => _sources;
  SourceConfig get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeParams => _activeParams;
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterialYou = true;
  bool _useAmoled = false;
  Locale _locale = const Locale('zh');
  
  // 外观设置
  double _cornerRadius = 24.0; 
  double _homeCornerRadius = 12.0;

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  bool get useAmoled => _useAmoled;
  Locale get locale => _locale;
  double get cornerRadius => _cornerRadius;
  double get homeCornerRadius => _homeCornerRadius;

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
    
    notifyListeners();
  }

  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index);
    _activeParams.clear();
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
    notifyListeners();
  }
  void updateSearchQuery(String q) {
    _activeParams['q'] = q;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) { _themeMode = mode; _prefs?.setString('themeMode', mode.name); notifyListeners(); }
  void setMaterialYou(bool v) { _useMaterialYou = v; _prefs?.setBool('useMaterialYou', v); notifyListeners(); }
  void setAmoled(bool v) { _useAmoled = v; _prefs?.setBool('useAmoled', v); notifyListeners(); }
  void setLanguage(String v) { _locale = Locale(v); _prefs?.setString('language', v); notifyListeners(); }
  
  void setCornerRadius(double value) { _cornerRadius = value; _prefs?.setDouble('corner_radius', value); notifyListeners(); }
  void setHomeCornerRadius(double value) { _homeCornerRadius = value; _prefs?.setDouble('home_corner_radius', value); notifyListeners(); }
}
