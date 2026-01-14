import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_source.dart';

class ThemeStore extends ChangeNotifier {
  // === 状态数据 ===
  ThemeMode _mode = ThemeMode.system;
  // 即使 UI 删除了设置项，变量仍需保留以兼容 AppTheme
  Color _accentColor = Colors.blue; 
  String _accentName = "蓝色";
  double _cornerRadius = 16.0;

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
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
      _saveToPrefs();
    }
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
    if (_currentSource.id != source.id) {
      _currentSource = source;
      notifyListeners();
      _saveToPrefs();
    }
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
    // 禁止删除内置源
    if (id == ImageSource.wallhaven.id) return;

    _sources.removeWhere((s) => s.id == id);
    // 如果删除了当前选中的源，重置为默认 Wallhaven
    if (_currentSource.id == id) {
      _currentSource = _sources.firstWhere(
        (s) => s.id == ImageSource.wallhaven.id,
        orElse: () => _sources.first,
      );
    }
    notifyListeners();
    _saveToPrefs();
  }

  // === 持久化逻辑 ===
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. 读取主题 (增加范围保护)
      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _mode = ThemeMode.values[modeIndex];
      }
      
      // 2. 读取圆角
      _cornerRadius = prefs.getDouble('corner_radius') ?? 16.0;
      
      // 3. 读取图源 (核心修复逻辑)
      final sourcesJson = prefs.getStringList('image_sources');
      if (sourcesJson != null) {
        final loadedSources = sourcesJson
            .map((e) => ImageSource.fromJson(jsonDecode(e)))
            .toList();

        // 🌟 关键逻辑：过滤掉旧的 Wallhaven 数据，使用代码中最新的
        // 这样可以确保"完美接入"，不受旧缓存数据的影响
        loadedSources.removeWhere((s) => s.id == ImageSource.wallhaven.id);
        
        // 重新构建列表：内置 Wallhaven + 用户自定义源
        _sources = [ImageSource.wallhaven, ...loadedSources];
      } else {
        // 首次启动，确保有 Wallhaven
        _sources = [ImageSource.wallhaven];
      }

      // 4. 读取当前选中图源
      final currentSourceId = prefs.getString('current_source_id');
      if (currentSourceId != null) {
        _currentSource = _sources.firstWhere(
          (s) => s.id == currentSourceId,
          // 如果找不到(比如被删了)，回退到 Wallhaven
          orElse: () => _sources.first,
        );
      } else {
        _currentSource = _sources.first;
      }
      
    } catch (e) {
      debugPrint("Load Prefs Error: $e");
    } finally {
      // 🌟 修复主题不生效的关键：
      // 无论加载成功还是失败，必须通知 UI 刷新，否则界面可能卡在默认状态
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', _mode.index);
    prefs.setDouble('corner_radius', _cornerRadius);
    // 序列化时，包含所有源
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
