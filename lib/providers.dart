import 'dart:convert'; // 新增：用于 JSON 转换
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =======================
// 1. 图源模型 (新增 JSON 转换能力)
// =======================
class ImageSource {
  final String name;
  final String baseUrl;
  final Map<String, dynamic> params;

  ImageSource({required this.name, required this.baseUrl, this.params = const {}});

  // 把对象转成 JSON 字符串 (存)
  Map<String, dynamic> toJson() => {
    'name': name,
    'baseUrl': baseUrl,
    'params': params,
  };

  // 把 JSON 字符串转成对象 (取)
  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      name: json['name'],
      baseUrl: json['baseUrl'],
      params: json['params'] ?? {},
    );
  }
}

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // 默认图源列表
  List<ImageSource> _sources = [
    ImageSource(name: 'Wallhaven (官方源)', baseUrl: 'https://wallhaven.cc/api/v1/search'),
    ImageSource(name: 'Wallhaven (动漫专区)', baseUrl: 'https://wallhaven.cc/api/v1/search', params: {'categories': '010'}), // 010 代表 Anime
    ImageSource(name: 'Wallhaven (三次元)', baseUrl: 'https://wallhaven.cc/api/v1/search', params: {'categories': '001'}), // 001 代表 People
  ];
  
  int _currentSourceIndex = 0;

  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _sources[_currentSourceIndex];

  // --- 主题与语言状态 ---
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterialYou = true;
  bool _useAmoled = false;
  Locale _locale = const Locale('zh');

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  bool get useAmoled => _useAmoled;
  Locale get locale => _locale;

  // 初始化：读取本地所有配置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 1. 读取主题
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;
    
    // 2. 读取语言
    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);

    // 3. 读取自定义图源 (核心逻辑)
    String? savedSources = _prefs?.getString('custom_sources');
    if (savedSources != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedSources);
        // 合并默认源 + 保存的源 (或者直接覆盖，这里选择覆盖以支持用户删除默认源的情况，但为了简单我们先覆盖)
        _sources = jsonList.map((e) => ImageSource.fromJson(e)).toList();
      } catch (e) {
        debugPrint("读取图源失败: $e");
      }
    }

    // 4. 读取上次选中的索引
    _currentSourceIndex = _prefs?.getInt('current_source_index') ?? 0;
    // 防止越界（比如删除了源导致索引失效）
    if (_currentSourceIndex >= _sources.length) _currentSourceIndex = 0;
    
    notifyListeners();
  }

  // --- 操作并保存 ---

  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index); // 保存选中项
    notifyListeners();
  }

  void addSource(String name, String url) {
    _sources.add(ImageSource(name: name, baseUrl: url));
    _saveSourcesToDisk(); // 保存列表
    notifyListeners();
  }
  
  // 内部方法：把整个图源列表存到本地
  void _saveSourcesToDisk() {
    String jsonString = jsonEncode(_sources.map((e) => e.toJson()).toList());
    _prefs?.setString('custom_sources', jsonString);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    notifyListeners();
  }

  void setMaterialYou(bool value) {
    _useMaterialYou = value;
    _prefs?.setBool('useMaterialYou', value);
    notifyListeners();
  }

  void setAmoled(bool value) {
    _useAmoled = value;
    _prefs?.setBool('useAmoled', value);
    notifyListeners();
  }

  void setLanguage(String code) {
    _locale = Locale(code);
    _prefs?.setString('language', code);
    notifyListeners();
  }
}
