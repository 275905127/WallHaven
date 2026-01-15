// lib/main.dart
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'theme/theme_store.dart';
import 'widgets/foggy_app_bar.dart';
import 'widgets/settings_widgets.dart';
import 'pages/sub_pages.dart';
import 'pages/filter_drawer.dart';
import 'pages/wallpaper_detail_page.dart';

// ✅ 新的 domain/data
import 'domain/entities/search_query.dart';
import 'domain/entities/wallpaper_item.dart';
import 'data/http/http_client.dart';
import 'data/repository/wallpaper_repository.dart';
import 'data/source_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  final themeStore = ThemeStore();
  runApp(
    ThemeScope(
      store: themeStore,
      child: ListenableBuilder(
        listenable: themeStore,
        builder: (context, child) => MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    final customBg = store.enableCustomColors ? store.customBackgroundColor : null;
    final customCard = store.enableCustomColors ? store.customCardColor : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: store.mode,
      theme: AppTheme.light(
        store.accentColor,
        customBg: customBg,
        customCard: customCard,
        cardRadius: store.cardRadius,
      ),
      darkTheme: AppTheme.dark(
        store.accentColor,
        customBg: customBg,
        customCard: customCard,
        cardRadius: store.cardRadius,
      ),
      home: const HomePage(),
    );
  }
}

// 🏠 首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _kFiltersPrefsKey = 'wallhaven_filters_v1';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  // ✅ UI 只持有 domain items
  final List<WallpaperItem> _items = [];

  int _page = 1;
  bool _isLoading = false;
  bool _isScrolled = false;
  bool _drawerOpen = false;

  String? _lastSourceConfigId;

  late final HttpClient _http;
  late final SourceFactory _factory;
  late final WallpaperRepository _repo;

  WallhavenFilters _filters = const WallhavenFilters();

  @override
  void initState() {
    super.initState();

    _http = HttpClient();
    _factory = SourceFactory(http: _http);

    // 临时占位，第一次 fetch 时会 setSource
    _repo = WallpaperRepository(_factory.fromStore(ThemeScope.of(context)));

    _bootstrap();

    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_scrollController.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  Future<void> _bootstrap() async {
    await _loadPersistedFilters();
    if (!mounted) return;
    await _initData();
  }

  Future<void> _loadPersistedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kFiltersPrefsKey);
      if (raw == null || raw.trim().isEmpty) return;

      final m = jsonDecode(raw);
      if (m is! Map) return;

      final next = WallhavenFilters(
        query: (m['query'] ?? '') as String,
        sorting: (m['sorting'] ?? 'toplist') as String,
        order: (m['order'] ?? 'desc') as String,
        categories: (m['categories'] ?? '111') as String,
        purity: (m['purity'] ?? '100') as String,
        resolutions: (m['resolutions'] ?? '') as String,
        ratios: (m['ratios'] ?? '') as String,
        atleast: (m['atleast'] ?? '') as String,
        colors: (m['colors'] ?? '') as String,
        topRange: (m['topRange'] ?? '1M') as String,
      );

      if (!mounted) return;
      setState(() => _filters = next);
    } catch (_) {}
  }

  Future<void> _persistFilters(WallhavenFilters f) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        'query': f.query,
        'sorting': f.sorting,
        'order': f.order,
        'categories': f.categories,
        'purity': f.purity,
        'resolutions': f.resolutions,
        'ratios': f.ratios,
        'atleast': f.atleast,
        'colors': f.colors,
        'topRange': f.topRange,
      };
      await prefs.setString(_kFiltersPrefsKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _clearPersistedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kFiltersPrefsKey);
    } catch (_) {}
  }

  Future<void> _initData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    _page = 1;
    _items.clear();

    await _fetchItems(page: 1);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final nextPage = _page + 1;
    final ok = await _fetchItems(page: nextPage);
    if (ok) _page = nextPage;

    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool> _fetchItems({required int page}) async {
    final store = ThemeScope.of(context);
    final f = _filters;

    try {
      // ✅ 切源：只在这里做“source 切换”，UI 不参与实例化细节
      final src = _factory.fromStore(store);
      _repo.setSource(src);

      // 暂时仍然用 WallhavenFilters 组 params（下一轮把这也 domain 化）
      final params = <String, dynamic>{
        'sorting': f.sorting,
        'order': f.order,
        'categories': f.categories,
        'purity': f.purity,
        'resolutions': f.resolutions.isEmpty ? null : f.resolutions,
        'ratios': f.ratios.isEmpty ? null : f.ratios,
        'q': f.query.isEmpty ? null : f.query,
        'atleast': f.atleast.isEmpty ? null : f.atleast,
        'colors': f.colors.isEmpty ? null : f.colors,
        'topRange': (f.sorting == 'toplist') ? f.topRange : null,
      }..removeWhere((k, v) => v == null);

      final newItems = await _repo.search(SearchQuery(page: page, params: params));

      if (!mounted) return false;
      setState(() => _items.addAll(newItems));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图源请求失败：$e')),
      );
      return false;
    }
  }

  Future<void> _onRefresh() async => _initData();

  void _applyFilters(WallhavenFilters f) {
    setState(() => _filters = f);
    _persistFilters(f);
    _initData();
  }

  void _resetFilters() {
    setState(() => _filters = const WallhavenFilters());
    _clearPersistedFilters();
    _initData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _http.dio.close(force: true);
    super.dispose();
  }

  double _drawerWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w * (2 / 3);
  }

  void _syncOverlayForDrawer(BuildContext context, bool open) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (open) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: theme.scaffoldBackgroundColor,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: theme.scaffoldBackgroundColor,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }
  }

  void _openSettingsFromDrawer() {
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final theme = Theme.of(context);

        // 切源自动刷新（只负责触发，不负责创建 source）
        final currentId = store.currentSourceConfig.id;
        if (_lastSourceConfigId == null) {
          _lastSourceConfigId = currentId;
        } else if (_lastSourceConfigId != currentId) {
          _lastSourceConfigId = currentId;
          if (!_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _initData();
            });
          }
        }

        final isDark = theme.brightness == Brightness.dark;
        final overlay = _drawerOpen
            ? SystemUiOverlayStyle(
                statusBarColor: theme.scaffoldBackgroundColor,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: theme.scaffoldBackgroundColor,
                systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              );

        final drawerRadius = store.cardRadius;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: Scaffold(
            key: _scaffoldKey,
            onDrawerChanged: (open) {
              _drawerOpen = open;
              _syncOverlayForDrawer(context, open);
              if (mounted) setState(() {});
            },
            drawerEnableOpenDragGesture: true,
            drawerEdgeDragWidth: 110,
            drawerDragStartBehavior: DragStartBehavior.down,
            drawer: Drawer(
              width: _drawerWidth(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(right: Radius.circular(drawerRadius)),
              ),
              clipBehavior: Clip.antiAlias,
              child: FilterDrawer(
                initial: _filters,
                onApply: _applyFilters,
                onReset: _resetFilters,
                onOpenSettings: _openSettingsFromDrawer,
              ),
            ),
            extendBodyBehindAppBar: true,
            appBar: FoggyAppBar(
              title: const Text("Wallhaven"),
              isScrolled: _isScrolled,
              fogStrength: 0.82,
              actions: const [],
            ),
            body: _items.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    edgeOffset: 100,
                    child: MasonryGridView.count(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 100, 12, 20),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];

                        final w = item.width <= 0 ? 1 : item.width;
                        final h = item.height <= 0 ? 1 : item.height;
                        final aspectRatio = (w / h).clamp(0.5, 2.0);

                        final imageUrl = item.preview.toString();

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WallpaperDetailPage(
                                id: item.id,
                                heroThumb: imageUrl,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(store.imageRadius),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: theme.cardColor,
                                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: theme.cardColor,
                                  child: const Center(child: Icon(Icons.error, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}