import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // 默认图源
  List<SourceConfig> _sources = [
    SourceConfig(
      name: 'Wallhaven',
      baseUrl: 'https://wallhaven.cc/api/v1/search',
      filters: [
        FilterGroup(title: '排序', paramName: 'sorting', type: 'radio', options: [
            FilterOption(label: '最新', value: 'date_added'),
            FilterOption(label: '最热', value: 'views'),
            FilterOption(label: '收藏', value: 'favorites'),
            FilterOption(label: '排行榜', value: 'toplist'),
        ]),
        FilterGroup(title: '分类', paramName: 'categories', type: 'bitmask', options: [
            FilterOption(label: 'General', value: 'General'),
            FilterOption(label: 'Anime', value: 'Anime'),
            FilterOption(label: 'People', value: 'People'),
        ]),
        FilterGroup(title: '分级', paramName: 'purity', type: 'bitmask', options: [
            FilterOption(label: 'SFW', value: 'SFW'),
            FilterOption(label: 'Sketchy', value: 'Sketchy'),
            FilterOption(label: 'NSFW', value: 'NSFW'),
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
  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  bool get useAmoled => _useAmoled;
  Locale get locale => _locale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;
    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);

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

  // === 新增：更新现有图源 ===
  void updateSource(int index, SourceConfig config) {
    if (index >= 0 && index < _sources.length) {
      _sources[index] = config;
      _saveSourcesToDisk();
      notifyListeners();
    }
  }

  // === 新增：删除图源 (顺手加上) ===
  void removeSource(int index) {
    if (_sources.length <= 1) return; // 至少保留一个
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
}
