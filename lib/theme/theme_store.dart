import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 需添加依赖
import '../models/image_source.dart';

class ThemeStore extends ChangeNotifier {
  // === 状态 ===
  ThemeMode _mode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";
  
  // 🌟 新增：自定义圆角 (默认 16.0)
  double _cornerRadius = 16.0;

  // 🌟 新增：图源管理
  List<ImageSource> _sources = [ImageSource.wallhaven];
  late ImageSource _currentSource;

  // === Getters ===
  ThemeMode get mode => _mode;
  Color get accentColor => _accentColor;
  String get accentName => _accentName;
  double get cornerRadius => _cornerRadius;
  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _currentSource;

  ThemeStore() {
    _currentSource = _sources.first; // 默认选中 Wallhaven
    _loadFromPrefs(); // 初始化时读取本地缓存
  }

  // === Actions ===

  // 1. 设置模式
  void setMode(ThemeMode newMode) {
    _mode = newMode;
    notifyListeners();
    _saveToPrefs();
  }

  // 2. 设置颜色
  void setAccent(Color newColor, String newName) {
    _accentColor = newColor;
    _accentName = newName;
    notifyListeners();
    _saveToPrefs();
  }

  // 3. 🌟 设置圆角
  void setCornerRadius(double radius) {
    _cornerRadius = radius;
    notifyListeners();
    _saveToPrefs();
  }

  // 4. 🌟 切换图源
  void setSource(ImageSource source) {
    _currentSource = source;
    notifyListeners();
    _saveToPrefs();
  }

  // 5. 🌟 添加图源
  void addSource(String name, String url) {
    final newSource = ImageSource(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      baseUrl: url,
    );
    _sources.add(newSource);
    notifyListeners();
    _saveToPrefs();
  }

  // 6. 删除图源
  void removeSource(String id) {
    _sources.removeWhere((s) => s.id == id);
    if (_currentSource.id == id) {
      _currentSource = _sources.first; // 如果删除了当前选中的，重置为默认
    }
    notifyListeners();
    _saveToPrefs();
  }

  // === 持久化逻辑 (SharedPreferences) ===
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 读取主题
    final modeIndex = prefs.getInt('theme_mode') ?? 0;
    _mode = ThemeMode.values[modeIndex];
    
    // 读取圆角
    _cornerRadius = prefs.getDouble('corner_radius') ?? 16.0;

    // 读取图源列表
    final sourcesJson = prefs.getStringList('image_sources');
    if (sourcesJson != null) {
      _sources = sourcesJson.map((e) => ImageSource.fromJson(jsonDecode(e))).toList();
      // 确保 Wallhaven 始终存在
      if (!_sources.any((s) => s.id == ImageSource.wallhaven.id)) {
        _sources.insert(0, ImageSource.wallhaven);
      }
    }

    // 读取当前图源 ID
    final currentSourceId = prefs.getString('current_source_id');
    if (currentSourceId != null) {
      _currentSource = _sources.firstWhere(
        (s) => s.id == currentSourceId,
        orElse: () => _sources.first,
      );
    }
    
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', _mode.index);
    prefs.setDouble('corner_radius', _cornerRadius);
    prefs.setStringList('image_sources', _sources.map((s) => jsonEncode(s.toJson())).toList());
    prefs.setString('current_source_id', _currentSource.id);
    // 颜色保存比较复杂(需存RGB值)，此处暂略，逻辑同上
  }
}

// Scope 保持不变
class ThemeScope extends InheritedWidget {
  final ThemeStore store;
  const ThemeScope({super.key, required this.store, required super.child});
  static ThemeStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.store;
  @override
  bool updateShouldNotify(ThemeScope oldWidget) => store != oldWidget.store;
}
