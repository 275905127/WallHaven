import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =======================
// 1. 图源模型 (只存地址和 Key，不再存筛选条件)
// =======================
class ImageSource {
  final String name;
  final String baseUrl;
  final String apiKey; // 新增：API Key 单独存

  ImageSource({
    required this.name, 
    required this.baseUrl, 
    this.apiKey = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
  };

  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      name: json['name'],
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'] ?? '',
    );
  }
}

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // --- 图源列表 ---
  List<ImageSource> _sources = [
    ImageSource(name: 'Wallhaven (默认)', baseUrl: 'https://wallhaven.cc/api/v1/search'),
  ];
  int _currentSourceIndex = 0;

  // --- 全局筛选状态 (像官网一样，随时可变) ---
  // 默认：全分类(111)、全分级(111 - 需Key)、最新排序
  Map<String, dynamic> _activeFilters = {
    'categories': '111', // General/Anime/People
    'purity': '100',     // SFW (默认安全)
    'sorting': 'date_added',
    'order': 'desc',
    'topRange': '1M',
    'q': '',             // 搜索关键词
  };

  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeFilters => _activeFilters;

  // --- 主题与语言 ---
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
    
    // 读取主题/语言
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;
    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);

    // 读取自定义图源
    String? savedSources = _prefs?.getString('custom_sources');
    if (savedSources != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedSources);
        _sources = jsonList.map((e) => ImageSource.fromJson(e)).toList();
      } catch (e) {
        debugPrint("读取图源失败: $e");
      }
    }
    _currentSourceIndex = _prefs?.getInt('current_source_index') ?? 0;
    if (_currentSourceIndex >= _sources.length) _currentSourceIndex = 0;
    
    notifyListeners();
  }

  // --- 核心：更新筛选条件 ---
  void updateFilters(Map<String, dynamic> newFilters) {
    _activeFilters.addAll(newFilters);
    notifyListeners(); // 通知首页刷新
  }

  // --- 核心：更新搜索关键词 ---
  void updateSearchQuery(String query) {
    _activeFilters['q'] = query;
    notifyListeners(); // 通知首页刷新
  }

  // --- 图源操作 ---
  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index);
    notifyListeners();
  }

  void addSource(String name, String apiKey) {
    // 默认都用官网 API，区别只是 API Key 不同
    const String defaultBaseUrl = 'https://wallhaven.cc/api/v1/search';
    _sources.add(ImageSource(name: name, baseUrl: defaultBaseUrl, apiKey: apiKey));
    _saveSourcesToDisk();
    notifyListeners();
  }
  
  void _saveSourcesToDisk() {
    String jsonString = jsonEncode(_sources.map((e) => e.toJson()).toList());
    _prefs?.setString('custom_sources', jsonString);
  }

  // --- 外观操作 ---
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    notifyListeners();
  }
  void setMaterialYou(bool v) { _useMaterialYou = v; _prefs?.setBool('useMaterialYou', v); notifyListeners(); }
  void setAmoled(bool v) { _useAmoled = v; _prefs?.setBool('useAmoled', v); notifyListeners(); }
  void setLanguage(String v) { _locale = Locale(v); _prefs?.setString('language', v); notifyListeners(); }
}
