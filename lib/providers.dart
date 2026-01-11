import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart';

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // --- 图源列表 ---
  List<SourceConfig> _sources = [
    // === 这里就是“配置驱动”的核心 ===
    // 我们手动定义好 Wallhaven 的规则，这就相当于“拉取”下来的配置
    SourceConfig(
      name: 'Wallhaven (默认)', 
      baseUrl: 'https://wallhaven.cc/api/v1/search',
      filters: [
        // 组 1: 排序 (通用)
        FilterGroup(
          title: '排序', 
          paramName: 'sorting', 
          type: 'radio', 
          options: [
            FilterOption(label: '最新', value: 'date_added'),
            FilterOption(label: '最热', value: 'views'),
            FilterOption(label: '收藏', value: 'favorites'),
            FilterOption(label: '排行榜', value: 'toplist'),
          ]
        ),
        // 组 2: 分类 (Wallhaven 特有的 bitmask)
        FilterGroup(
          title: '分类', 
          paramName: 'categories', 
          type: 'bitmask', // 我们专门定义这种类型处理 111/010
          options: [
            FilterOption(label: '常规', value: 'General'), // 对应 bitmask 第1位
            FilterOption(label: '动漫', value: 'Anime'),   // 对应 bitmask 第2位
            FilterOption(label: '人物', value: 'People'),  // 对应 bitmask 第3位
          ]
        ),
        // 组 3: 分级
        FilterGroup(
          title: '分级', 
          paramName: 'purity', 
          type: 'bitmask', 
          options: [
            FilterOption(label: '安全', value: 'SFW'),
            FilterOption(label: '擦边', value: 'Sketchy'),
            FilterOption(label: '限制级', value: 'NSFW'),
          ]
        ),
      ]
    ),
  ];
  int _currentSourceIndex = 0;

  // 存储当前的筛选值：{ 'sorting': 'views', 'categories': '100' }
  Map<String, dynamic> _activeParams = {};

  List<SourceConfig> get sources => _sources;
  SourceConfig get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeParams => _activeParams;

  // --- 基础部分保持不变 ---
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

    String? savedSources = _prefs?.getString('generic_sources_v2'); // 升级 key 防止冲突
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
    // 切换图源时，清空筛选参数，防止参数污染
    _activeParams.clear();
    notifyListeners();
  }

  void addSource(SourceConfig config) {
    _sources.add(config);
    _saveSourcesToDisk();
    notifyListeners();
  }
  
  void _saveSourcesToDisk() {
    String jsonString = jsonEncode(_sources.map((e) => e.toJson()).toList());
    _prefs?.setString('generic_sources_v2', jsonString);
  }

  // --- 通用参数更新逻辑 ---
  void updateParam(String key, dynamic value) {
    _activeParams[key] = value;
    notifyListeners();
  }
  
  void updateSearchQuery(String q) {
    _activeParams['q'] = q;
    notifyListeners();
  }

  // 外观方法
  void setThemeMode(ThemeMode mode) { _themeMode = mode; _prefs?.setString('themeMode', mode.name); notifyListeners(); }
  void setMaterialYou(bool v) { _useMaterialYou = v; _prefs?.setBool('useMaterialYou', v); notifyListeners(); }
  void setAmoled(bool v) { _useAmoled = v; _prefs?.setBool('useAmoled', v); notifyListeners(); }
  void setLanguage(String v) { _locale = Locale(v); _prefs?.setString('language', v); notifyListeners(); }
}
