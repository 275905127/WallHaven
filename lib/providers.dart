import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart'; // 引入刚才建的模型

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // --- 图源列表 (支持任意网站) ---
  List<SourceConfig> _sources = [
    // 默认可以给一个示例，但理论上可以是空的
    SourceConfig(
      name: 'Wallhaven (示例)', 
      baseUrl: 'https://wallhaven.cc/api/v1/search',
      // 解析规则默认就是适配 Wallhaven 的，所以不用特意写，但为了展示灵活性：
      listKey: 'data',
      thumbKey: 'thumbs.large',
      fullKey: 'path'
    ),
  ];
  int _currentSourceIndex = 0;

  // --- 筛选状态 ---
  Map<String, dynamic> _activeFilters = {
    'sorting': 'date_added',
    'page': 1,
    'q': '', 
    // 注意：不同网站的筛选参数可能不同，这里作为通用容器，
    // 我们暂时保留通用的 sort/page/q，特定网站的参数以后可以在 SourceConfig 里扩展 map
  };

  List<SourceConfig> get sources => _sources;
  SourceConfig get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeFilters => _activeFilters;

  // --- 主题与语言 (保持不变) ---
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
    
    // 读取外观配置
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;
    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);

    // 读取自定义图源
    String? savedSources = _prefs?.getString('generic_sources');
    if (savedSources != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedSources);
        if (jsonList.isNotEmpty) {
           _sources = jsonList.map((e) => SourceConfig.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint("读取图源失败: $e");
      }
    }
    
    _currentSourceIndex = _prefs?.getInt('current_source_index') ?? 0;
    if (_currentSourceIndex >= _sources.length) _currentSourceIndex = 0;
    
    notifyListeners();
  }

  // --- 图源操作 ---
  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index);
    notifyListeners();
  }

  // 添加通用图源
  void addSource(SourceConfig config) {
    _sources.add(config);
    _saveSourcesToDisk();
    notifyListeners();
  }
  
  void _saveSourcesToDisk() {
    String jsonString = jsonEncode(_sources.map((e) => e.toJson()).toList());
    _prefs?.setString('generic_sources', jsonString);
  }

  // --- 筛选操作 ---
  void updateSearchQuery(String query) {
    _activeFilters['q'] = query;
    notifyListeners();
  }
  
  // 更新通用参数
  void updateParam(String key, dynamic value) {
    _activeFilters[key] = value;
    notifyListeners();
  }

  // --- 外观操作 (保持不变) ---
  void setThemeMode(ThemeMode mode) { _themeMode = mode; _prefs?.setString('themeMode', mode.name); notifyListeners(); }
  void setMaterialYou(bool v) { _useMaterialYou = v; _prefs?.setBool('useMaterialYou', v); notifyListeners(); }
  void setAmoled(bool v) { _useAmoled = v; _prefs?.setBool('useAmoled', v); notifyListeners(); }
  void setLanguage(String v) { _locale = Locale(v); _prefs?.setString('language', v); notifyListeners(); }
}
