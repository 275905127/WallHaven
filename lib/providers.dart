import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =======================
// 1. 图源模型与管理
// =======================
class ImageSource {
  final String name;
  final String baseUrl; // 例如 'https://wallhaven.cc/api/v1/search'
  final Map<String, dynamic> params; // 默认参数

  ImageSource({required this.name, required this.baseUrl, this.params = const {}});
  
  // 转换为 JSON 存本地 (简化版，实际可用 jsonEncode)
}

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // --- 图源状态 ---
  List<ImageSource> _sources = [
    ImageSource(name: 'Wallhaven (官方源)', baseUrl: 'https://wallhaven.cc/api/v1/search'),
    ImageSource(name: 'Wallhaven (动漫专区)', baseUrl: 'https://wallhaven.cc/api/v1/search', params: {'categories': '010'}),
    ImageSource(name: 'Wallhaven (三次元)', baseUrl: 'https://wallhaven.cc/api/v1/search', params: {'categories': '001'}),
  ];
  int _currentSourceIndex = 0;

  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _sources[_currentSourceIndex];

  // --- 主题状态 ---
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterialYou = true; // 动态取色
  bool _useAmoled = false;     // 纯黑背景

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  bool get useAmoled => _useAmoled;

  // --- 语言状态 ---
  Locale _locale = const Locale('zh');
  Locale get locale => _locale;

  // 初始化读取本地配置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // 读取主题
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;
    
    // 读取语言
    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);
    
    notifyListeners();
  }

  // 切换图源
  void setSource(int index) {
    _currentSourceIndex = index;
    notifyListeners();
  }

  // 添加新图源
  void addSource(String name, String url) {
    _sources.add(ImageSource(name: name, baseUrl: url));
    notifyListeners();
  }

  // 切换主题模式
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs?.setString('themeMode', mode.name);
    notifyListeners();
  }

  // 切换动态取色
  void setMaterialYou(bool value) {
    _useMaterialYou = value;
    _prefs?.setBool('useMaterialYou', value);
    notifyListeners();
  }

  // 切换纯黑模式
  void setAmoled(bool value) {
    _useAmoled = value;
    _prefs?.setBool('useAmoled', value);
    notifyListeners();
  }

  // 切换语言
  void setLanguage(String code) {
    _locale = Locale(code);
    _prefs?.setString('language', code);
    notifyListeners();
  }
}
