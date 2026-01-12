import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/source_config.dart';
import 'models/wallpaper.dart';

// === 全局常量：统一 User-Agent ===
const Map<String, String> kAppHeaders = {
  "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
  "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
};

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;

  // === 默认图源列表 ===
  List<SourceConfig> _sources = [
    // 1. Wallhaven (经典源)
    SourceConfig(
      name: 'Wallhaven',
      baseUrl: 'https://wallhaven.cc/api/v1/search',
      filters: [
        FilterGroup(title: '分类 (Categories)', paramName: 'categories', type: 'bitmask', options: [
            FilterOption(label: '常规', value: 'General'),
            FilterOption(label: '动漫', value: 'Anime'),
            FilterOption(label: '人物', value: 'People'),
        ]),
        FilterGroup(title: '分级 (Purity)', paramName: 'purity', type: 'bitmask', options: [
            FilterOption(label: 'SFW', value: 'SFW'),
            FilterOption(label: 'Sketchy', value: 'Sketchy'),
            FilterOption(label: 'NSFW', value: 'NSFW'),
        ]),
        FilterGroup(title: '排序 (Sorting)', paramName: 'sorting', type: 'radio', options: [
            FilterOption(label: '最新', value: 'date_added'),
            FilterOption(label: '相关', value: 'relevance'),
            FilterOption(label: '随机', value: 'random'),
            FilterOption(label: '浏览', value: 'views'),
            FilterOption(label: '收藏', value: 'favorites'),
            FilterOption(label: '排行', value: 'toplist'),
        ]),
        FilterGroup(title: '排行榜范围', paramName: 'topRange', type: 'radio', options: [
            FilterOption(label: '1月', value: '1M'),
            FilterOption(label: '1年', value: '1y'),
        ]),
      ]
    ),

    // 2. Luvbree (随机图源 - 修复筛选参数)
    // 注意：Luvbree 这类 API 的参数名通常与 Wallhaven 不同
    SourceConfig(
      name: 'Luvbree (Setu)',
      baseUrl: 'https://api.luvbree.com/api/setu/v2', // 示例 URL，请替换为你实际使用的 URL
      listKey: 'data', // 通常返回 {data: [...]}
      filters: [
        // 修复：使用 'r18' 而不是 'purity'
        FilterGroup(title: '内容分级 (NSFW)', paramName: 'r18', type: 'radio', options: [
            FilterOption(label: '安全 (SFW)', value: '0'), // 0: 非R18
            FilterOption(label: '色图 (NSFW)', value: '1'), // 1: R18
        ]),
        // 修复：使用 'sort' 控制横竖屏
        FilterGroup(title: '图片方向', paramName: 'sort', type: 'radio', options: [
            FilterOption(label: '随机', value: ''),
            FilterOption(label: '竖屏 (手机)', value: 'mp'), // Mobile Portrait
            FilterOption(label: '横屏 (电脑)', value: 'pc'), // PC
        ]),
        // 修复：使用 'size' 控制画质
        FilterGroup(title: '图片画质', paramName: 'size', type: 'radio', options: [
            FilterOption(label: '原图 (高清)', value: 'original'),
            FilterOption(label: '压缩 (省流)', value: 'regular'),
        ]),
        // 修复：使用 'tag' 或 'keyword' 控制类型 (根据具体API调整)
        FilterGroup(title: '图片类型', paramName: 'tag', type: 'radio', options: [
            FilterOption(label: '默认', value: ''),
            FilterOption(label: '二次元', value: '二次元'), 
            FilterOption(label: '三次元', value: '三次元'),
            FilterOption(label: '白丝', value: '白丝'),
            FilterOption(label: '黑丝', value: '黑丝'),
        ]),
      ]
    ),
  ];

  int _currentSourceIndex = 0;
  Map<String, dynamic> _activeParams = {};
  
  // 收藏列表
  List<Wallpaper> _favorites = [];

  // Getters
  List<SourceConfig> get sources => _sources;
  SourceConfig get currentSource => _sources[_currentSourceIndex];
  Map<String, dynamic> get activeParams => _activeParams;
  List<Wallpaper> get favorites => _favorites;
  
  // 主题与外观
  ThemeMode _themeMode = ThemeMode.system;
  bool _useMaterialYou = true;
  bool _useAmoled = false;
  Locale _locale = const Locale('zh');
  double _cornerRadius = 16.0; 
  double _homeCornerRadius = 12.0;
  Color? _customScaffoldColor;
  Color? _customCardColor;

  ThemeMode get themeMode => _themeMode;
  bool get useMaterialYou => _useMaterialYou;
  bool get useAmoled => _useAmoled;
  Locale get locale => _locale;
  double get cornerRadius => _cornerRadius;
  double get homeCornerRadius => _homeCornerRadius;
  Color? get customScaffoldColor => _customScaffoldColor;
  Color? get customCardColor => _customCardColor;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 1. 读取外观配置
    String? mode = _prefs?.getString('themeMode');
    if (mode == 'light') _themeMode = ThemeMode.light;
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    _useMaterialYou = _prefs?.getBool('useMaterialYou') ?? true;
    _useAmoled = _prefs?.getBool('useAmoled') ?? false;
    String? lang = _prefs?.getString('language');
    if (lang != null) _locale = Locale(lang);

    _cornerRadius = _prefs?.getDouble('corner_radius') ?? 16.0;
    _homeCornerRadius = _prefs?.getDouble('home_corner_radius') ?? 12.0;

    int? scaffoldColorVal = _prefs?.getInt('custom_scaffold_color');
    if (scaffoldColorVal != null) _customScaffoldColor = Color(scaffoldColorVal);
    
    int? cardColorVal = _prefs?.getInt('custom_card_color');
    if (cardColorVal != null) _customCardColor = Color(cardColorVal);

    // 2. 读取图源 (如果有本地保存的图源，覆盖默认的)
    String? savedSources = _prefs?.getString('generic_sources_v2');
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
    
    // 3. 读取收藏
    String? savedFavs = _prefs?.getString('my_favorites_v1');
    if (savedFavs != null) {
      try {
        List<dynamic> jsonList = jsonDecode(savedFavs);
        _favorites = jsonList.map((e) => Wallpaper.fromJson(e)).toList();
      } catch (e) {
        debugPrint("收藏读取错误: $e");
      }
    }

    // 4. 读取当前图源的筛选参数 (修复重启重置问题)
    _loadFiltersForCurrentSource();
    
    notifyListeners();
  }

  // === 筛选持久化逻辑 (核心修复) ===
  void _loadFiltersForCurrentSource() {
    // 针对每个图源单独存储筛选条件
    final key = "filters_${currentSource.name}_${currentSource.baseUrl.hashCode}";
    String? savedFilters = _prefs?.getString(key);
    if (savedFilters != null) {
      try {
        _activeParams = jsonDecode(savedFilters);
      } catch (e) {
        _activeParams = {};
      }
    } else {
      _activeParams = {};
    }
  }

  void _saveFiltersForCurrentSource() {
    final key = "filters_${currentSource.name}_${currentSource.baseUrl.hashCode}";
    _prefs?.setString(key, jsonEncode(_activeParams));
  }

  // === 收藏逻辑 ===
  bool isFavorite(Wallpaper wallpaper) {
    return _favorites.any((e) => e.id == wallpaper.id);
  }

  void toggleFavorite(Wallpaper wallpaper) {
    if (isFavorite(wallpaper)) {
      _favorites.removeWhere((e) => e.id == wallpaper.id);
    } else {
      _favorites.add(wallpaper);
    }
    _saveFavorites();
    notifyListeners();
  }

  void _saveFavorites() {
    String jsonString = jsonEncode(_favorites.map((e) => e.toJson()).toList());
    _prefs?.setString('my_favorites_v1', jsonString);
  }

  // === 图源操作 ===
  void setSource(int index) {
    _currentSourceIndex = index;
    _prefs?.setInt('current_source_index', index);
    _loadFiltersForCurrentSource(); // 切换源时，加载该源的筛选条件
    notifyListeners();
  }

  void addSource(SourceConfig config) {
    _sources.add(config);
    _saveSourcesToDisk();
    notifyListeners();
  }

  void updateSource(int index, SourceConfig config) {
    if (index >= 0 && index < _sources.length) {
      _sources[index] = config;
      _saveSourcesToDisk();
      notifyListeners();
    }
  }

  void removeSource(int index) {
    if (_sources.length <= 1) return; 
    _sources.removeAt(index);
    if (_currentSourceIndex >= _sources.length) {
      _currentSourceIndex = 0;
    }
    _saveSourcesToDisk();
    _loadFiltersForCurrentSource();
    notifyListeners();
  }
  
  bool importSourceConfig(String jsonString) {
    try {
      final Map<String, dynamic> map = jsonDecode(jsonString);
      final config = SourceConfig.fromJson(map);
      addSource(config);
      return true;
    } catch (e) {
      debugPrint("导入失败: $e");
      return false;
    }
  }

  void _saveSourcesToDisk() {
    String jsonString = jsonEncode(_sources.map((e) => e.toJson()).toList());
    _prefs?.setString('generic_sources_v2', jsonString);
  }

  // === 参数更新 ===
  void updateParam(String key, dynamic value) {
    _activeParams[key] = value;
    _saveFiltersForCurrentSource(); // 每次修改立即保存
    notifyListeners();
  }
  
  void updateSearchQuery(String q) {
    _activeParams['q'] = q; // 搜索词通常用 q 或 keyword
    _saveFiltersForCurrentSource();
    notifyListeners();
  }

  // === 外观设置 ===
  void setThemeMode(ThemeMode mode) { _themeMode = mode; _prefs?.setString('themeMode', mode.name); notifyListeners(); }
  void setMaterialYou(bool v) { _useMaterialYou = v; _prefs?.setBool('useMaterialYou', v); notifyListeners(); }
  void setAmoled(bool v) { _useAmoled = v; _prefs?.setBool('useAmoled', v); notifyListeners(); }
  void setLanguage(String v) { _locale = Locale(v); _prefs?.setString('language', v); notifyListeners(); }
  
  void setCornerRadius(double value) { _cornerRadius = value; _prefs?.setDouble('corner_radius', value); notifyListeners(); }
  void setHomeCornerRadius(double value) { _homeCornerRadius = value; _prefs?.setDouble('home_corner_radius', value); notifyListeners(); }

  void setCustomScaffoldColor(Color? color) {
    _customScaffoldColor = color;
    if (color == null) {
      _prefs?.remove('custom_scaffold_color');
    } else {
      _prefs?.setInt('custom_scaffold_color', color.value);
    }
    notifyListeners();
  }

  void setCustomCardColor(Color? color) {
    _customCardColor = color;
    if (color == null) {
      _prefs?.remove('custom_card_color');
    } else {
      _prefs?.setInt('custom_card_color', color.value);
    }
    notifyListeners();
  }
}
