import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/image_source.dart';

// 🌟 新增：全局 ThemeScope 定义，放在 Store 文件中确保全局可引用
class ThemeScope extends InheritedWidget {
  final ThemeStore store;
  const ThemeScope({super.key, required this.store, required super.child});

  static ThemeStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    if (scope == null) return ThemeStore(); // 安全回退
    return scope.store;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => store != oldWidget.store;
}

class ThemeStore extends ChangeNotifier {
  // === 状态数据 ===
  ThemeMode _mode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  String _accentName = "蓝色";
  
  double _cardRadius = 16.0;   
  double _imageRadius = 12.0;  

  bool _enableCustomColors = false; 

  Color? _customBackgroundColor; 
  Color? _customCardColor;

  List<ImageSource> _sources = [ImageSource.wallhaven];
  late ImageSource _currentSource;

  // === Getters ===
  ThemeMode get mode => _mode;
  Color get accentColor => _accentColor;
  String get accentName => _accentName;
  
  double get cardRadius => _cardRadius;
  double get imageRadius => _imageRadius;
  
  bool get enableCustomColors => _enableCustomColors;

  Color? get customBackgroundColor => _customBackgroundColor;
  Color? get customCardColor => _customCardColor;

  List<ImageSource> get sources => _sources;
  ImageSource get currentSource => _currentSource;

  ThemeStore() {
    _currentSource = _sources.first; 
    _loadFromPrefs(); 
  }

  // === Actions ===
  
  void setMode(ThemeMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
      savePreferences();
    }
  }

  void setAccent(Color newColor, String newName) {
    _accentColor = newColor;
    _accentName = newName;
    notifyListeners();
    savePreferences();
  }

  void setEnableCustomColors(bool value) {
    if (_enableCustomColors != value) {
      _enableCustomColors = value;
      notifyListeners();
      savePreferences();
    }
  }

  void setCardRadius(double radius) {
    if (_cardRadius != radius) {
      _cardRadius = radius;
      notifyListeners(); 
    }
  }

  void setImageRadius(double radius) {
    if (_imageRadius != radius) {
      _imageRadius = radius;
      notifyListeners();
    }
  }

  void setCustomBackgroundColor(Color? color) {
    if (_customBackgroundColor != color) {
      _customBackgroundColor = color;
      notifyListeners();
      savePreferences();
    }
  }

  void setCustomCardColor(Color? color) {
    if (_customCardColor != color) {
      _customCardColor = color;
      notifyListeners();
      savePreferences();
    }
  }

  void setSource(ImageSource source) {
    if (_currentSource.id != source.id) {
      _currentSource = source;
      notifyListeners();
      savePreferences();
    }
  }

  void addSource(String name, String url, {String? username, String? apiKey}) {
    final newSource = ImageSource(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      baseUrl: url,
      username: username,
      apiKey: apiKey,
    );
    _sources.add(newSource);
    notifyListeners();
    savePreferences();
  }

  void updateSource(ImageSource updatedSource) {
    final index = _sources.indexWhere((s) => s.id == updatedSource.id);
    if (index != -1) {
      _sources[index] = updatedSource;
      if (_currentSource.id == updatedSource.id) {
        _currentSource = updatedSource;
      }
      notifyListeners();
      savePreferences();
    }
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
    savePreferences();
  }

  // === 持久化逻辑 ===
  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', _mode.index);
    prefs.setBool('enable_custom_colors', _enableCustomColors);
    prefs.setDouble('card_radius', _cardRadius);
    prefs.setDouble('image_radius', _imageRadius);
    
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

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('theme_mode') ?? 0;
      if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
        _mode = ThemeMode.values[modeIndex];
      }
      _enableCustomColors = prefs.getBool('enable_custom_colors') ?? false;
      _cardRadius = prefs.getDouble('card_radius') ?? 16.0;
      _imageRadius = prefs.getDouble('image_radius') ?? 12.0;
      final bgVal = prefs.getInt('custom_bg_color');
      _customBackgroundColor = bgVal != null ? Color(bgVal) : null;
      final cardVal = prefs.getInt('custom_card_color');
      _customCardColor = cardVal != null ? Color(cardVal) : null;
      final sourcesJson = prefs.getStringList('image_sources');
      if (sourcesJson != null) {
        final loadedSources = sourcesJson.map((e) => ImageSource.fromJson(jsonDecode(e))).toList();
        loadedSources.removeWhere((s) => s.id == ImageSource.wallhaven.id);
        _sources = [ImageSource.wallhaven, ...loadedSources];
      }
      final currentSourceId = prefs.getString('current_source_id');
      if (currentSourceId != null) {
        _currentSource = _sources.firstWhere((s) => s.id == currentSourceId, orElse: () => _sources.first);
      }
    } catch (e) {
      debugPrint("Load Prefs Error: $e");
    } finally {
      notifyListeners();
    }
  }
}
