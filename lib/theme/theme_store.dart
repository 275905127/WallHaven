import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_source.dart';

class ThemeStore extends ChangeNotifier {
  // === 状态数据 ===
  ThemeMode _mode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";
  double _cornerRadius = 16.0; // 自定义圆角

  // 图源数据
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
    _currentSource = _sources.first; 
    _loadFromPrefs(); // 启动时读取缓存
  }

  // === 修改并保存 ===
  
  void setMode(ThemeMode newMode) {
    _mode = newMode;
    notifyListeners();
    _saveToPrefs();
  }

  void setAccent(Color newColor, String newName) {
    _accentColor = newColor;
    _accentName = newName;
    notifyListeners();
    _saveToPrefs();
  }

  void setCornerRadius(double radius) {
    _cornerRadius = radius;
    notifyListeners();
    _saveToPrefs();
  }

  void setSource(ImageSource source) {
    _currentSource = source;
    notifyListeners();
    _saveToPrefs();
  }

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

  void removeSource(String id) {
    _sources.removeWhere((s) => s.id == id);
    if (_currentSource.id == id) {
      _currentSource = _sources.first;
    }
    notifyListeners();
    _saveToPrefs();
  }

  // === 持久化逻辑 ===
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 读取主题
    final modeIndex = prefs.getInt('theme_mode') ?? 0;
    _mode = ThemeMode.values[modeIndex];
    
    // 读取圆角
    _cornerRadius = prefs.getDouble('corner_radius') ?? 16.0;
    
    // 读取颜色 (这里简化处理，真实项目应存RGB值)
    // 暂略颜色的持久化，优先保证逻辑通畅

    // 读取图源
    final sourcesJson = prefs.getStringList('image_sources');
    if (sourcesJson != null) {
      try {
        _sources = sourcesJson.map((e) => ImageSource.fromJson(jsonDecode(e))).toList();
        // 确保 Wallhaven 始终在列表里
        if (!_sources.any((s) => s.id == ImageSource.wallhaven.id)) {
          _sources.insert(0, ImageSource.wallhaven);
        }
      } catch (e) {
        print("图源加载失败，重置为默认");
      }
    }

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
  }
}

// Scope
class ThemeScope extends InheritedWidget {
  final ThemeStore store;
  const ThemeScope({super.key, required this.store, required super.child});
  static ThemeStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.store;
  @override
  bool updateShouldNotify(ThemeScope oldWidget) => store != oldWidget.store;
}
