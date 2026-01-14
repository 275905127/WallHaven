import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_source.dart';

class ThemeStore extends ChangeNotifier {
  // === 状态数据 ===
  ThemeMode _mode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";
  
  // 🌟 新增：拆分圆角设置
  double _cardRadius = 16.0;   // 设置页卡片圆角 (默认 16)
  double _imageRadius = 12.0;  // 首页瀑布流图片圆角 (默认 12)

  // 🌟 新增：自定义颜色 (可为空，为空则跟随系统默认)
  Color? _customBackgroundColor; 
  Color? _customCardColor;

  // 图源数据
  List<ImageSource> _sources = [ImageSource.wallhaven];
  late ImageSource _currentSource;

  // === Getters ===
  ThemeMode get mode => _mode;
  Color get accentColor => _accentColor;
  String get accentName => _accentName;
  
  double get cardRadius => _cardRadius;
  double get imageRadius => _imageRadius;
  
  Color? get customBackgroundColor => _customBackgroundColor;
  Color? get customCardColor => _customCardColor;

  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _currentSource;

  ThemeStore() {
    _currentSource = _sources.first; 
    _loadFromPrefs(); // 启动时读取缓存
  }

  // === Actions ===
  
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

  // 🌟 设置卡片圆角
  void setCardRadius(double radius) {
    if (_cardRadius != radius) {
      _cardRadius = radius;
      notifyListeners();
      _saveToPrefs();
    }
  }

  // 🌟 设置图片圆角
  void setImageRadius(double radius) {
    if (_imageRadius != radius) {
      _imageRadius = radius;
      notifyListeners();
      _saveToPrefs();
    }
  }

  // 🌟 设置自定义背景色 (传 null 恢复默认)
  void setCustomBackgroundColor(Color? color) {
    if (_customBackgroundColor != color) {
      _customBackgroundColor = color;
      notifyListeners();
      _saveToPrefs();
    }
  }

  // 🌟 设置自定义卡片色 (传 null 恢复默认)
  void setCustomCardColor(Color? color) {
    if (_customCardColor != color) {
      _customCardColor = color;
      notifyListeners();
      _saveToPrefs();
    }
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
    if (id == ImageSource.wallhaven.id) return;

    _sources.removeWhere((s) => s.id == id);
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
      
      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _mode = ThemeMode.values[modeIndex];
      }
      
      // 读取圆角 (兼容旧 key 'corner_radius' 迁移到 'card_radius')
      _cardRadius = prefs.getDouble('card_radius') ?? prefs.getDouble('corner_radius') ?? 16.0;
      _imageRadius = prefs.getDouble('image_radius') ?? 12.0;

      // 读取自定义颜色 (保存的是 int 值)
      final bgVal = prefs.getInt('custom_bg_color');
      _customBackgroundColor = bgVal != null ? Color(bgVal) : null;
      
      final cardVal = prefs.getInt('custom_card_color');
      _customCardColor = cardVal != null ? Color(cardVal) : null;
      
      // 读取图源
      final sourcesJson = prefs.getStringList('image_sources');
      if (sourcesJson != null) {
        final loadedSources = sourcesJson
            .map((e) => ImageSource.fromJson(jsonDecode(e)))
            .toList();
        loadedSources.removeWhere((s) => s.id == ImageSource.wallhaven.id);
        _sources = [ImageSource.wallhaven, ...loadedSources];
      } else {
        _sources = [ImageSource.wallhaven];
      }

      final currentSourceId = prefs.getString('current_source_id');
      if (currentSourceId != null) {
        _currentSource = _sources.firstWhere(
          (s) => s.id == currentSourceId,
          orElse: () => _sources.first,
        );
      } else {
        _currentSource = _sources.first;
      }
      
    } catch (e) {
      debugPrint("Load Prefs Error: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', _mode.index);
    
    // 保存圆角
    prefs.setDouble('card_radius', _cardRadius);
    prefs.setDouble('image_radius', _imageRadius);
    
    // 保存颜色 (存 int 值，null 则移除 Key)
    if (_customBackgroundColor != null) {
      prefs.setInt('custom_bg_color', _customBackgroundColor!.value);
    } else {
      prefs.remove('custom_bg_color');
    }
    
    if (_customCardColor != null) {
      prefs.setInt('custom_card_color', _customCardColor!.value);
    } else {
      prefs.remove('custom_card_color');
    }

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
