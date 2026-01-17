//  lib/main.dart
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/http/http_client.dart';
import 'data/repository/wallpaper_repository.dart';
import 'data/source_factory.dart';
import 'domain/entities/filter_spec.dart';
import 'domain/entities/search_query.dart';
import 'domain/entities/source_capabilities.dart';
import 'domain/entities/wallpaper_item.dart';
import 'pages/filter_drawer.dart';
import 'pages/settings_page.dart';
import 'pages/wallpaper_detail_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_store.dart';
import 'widgets/foggy_app_bar.dart';

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
        builder: (context, child) => const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  static const String _kFiltersPrefsKey = 'filters_v2';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  final List<WallpaperItem> _items = [];

  int _page = 1;
  bool _isLoading = false;
  bool _isScrolled = false;
  bool _drawerOpen = false;

  String? _lastSourceConfigId;

  late final HttpClient _http;
  late final SourceFactory _factory;
  WallpaperRepository? _repo; // ✅ 依赖 ThemeScope，不能在 initState 里 new

  FilterSpec _filters = const FilterSpec();

  bool _didInitDeps = false; // ✅ 防止 didChangeDependencies 重复初始化

  @override
  void initState() {
    super.initState();

    // ✅ 这些不依赖 context，可以留在 initState
    _http = HttpClient();
    _factory = SourceFactory(http: _http);

    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }

      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDeps) return;
    _didInitDeps = true;

    // ✅ 只能在这里（或 build）里依赖 ThemeScope.of(context)
    final store = ThemeScope.of(context);

    // 初始化 repo（依赖当前 source）
    _repo = WallpaperRepository(_factory.fromStore(store));

    // 启动流程（只跑一次）
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadPersistedFilters();
    if (!mounted) return;
    await _initData();
  }

  Map<String, dynamic> _filtersToJson(FilterSpec f) => {
        'text': f.text,
        'sortBy': f.sortBy?.name,
        'order': f.order?.name,
        'resolutions': f.resolutions.toList(),
        'atleast': f.atleast,
        'ratios': f.ratios.toList(),
        'color': f.color,
        'rating': f.rating.map((e) => e.name).toList(),
        'categories': f.categories.toList(),
        'timeRange': f.timeRange,
      };

  FilterSpec _filtersFromJson(Map<String, dynamic> m) {
    Set<String> toSet(dynamic v) {
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((s) => s.trim().isNotEmpty).toSet();
      }
      return <String>{};
    }

    SortBy? sortByFrom(dynamic v) {
      if (v is! String) return null;
      for (final e in SortBy.values) {
        if (e.name == v) return e;
      }
      return null;
    }

    SortOrder? orderFrom(dynamic v) {
      if (v is! String) return null;
      for (final e in SortOrder.values) {
        if (e.name == v) return e;
      }
      return null;
    }

    Set<RatingLevel> ratingFrom(dynamic v) {
      final out = <RatingLevel>{};
      if (v is! List) return out;
      for (final x in v) {
        final s = x?.toString();
        if (s == null) continue;
        for (final e in RatingLevel.values) {
          if (e.name == s) out.add(e);
        }
      }
      return out;
    }

    String? toOptString(dynamic v) {
      if (v is String) {
        final t = v.trim();
        return t.isEmpty ? null : t;
      }
      return null;
    }

    return FilterSpec(
      text: (m['text'] is String) ? (m['text'] as String) : '',
      sortBy: sortByFrom(m['sortBy']),
      order: orderFrom(m['order']),
      resolutions: toSet(m['resolutions']),
      atleast: toOptString(m['atleast']),
      ratios: toSet(m['ratios']),
      color: toOptString(m['color']),
      rating: ratingFrom(m['rating']),
      categories: toSet(m['categories']),
      timeRange: toOptString(m['timeRange']),
    );
  }

  Future<void> _loadPersistedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kFiltersPrefsKey);
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final next = _filtersFromJson(decoded.cast<String, dynamic>());
      if (!mounted) return;
      setState(() => _filters = next);
    } catch (_) {}
  }

  Future<void> _persistFilters(FilterSpec f) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kFiltersPrefsKey, jsonEncode(_filtersToJson(f)));
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
    if (_repo == null) return;

    setState(() => _isLoading = true);

    _page = 1;
    _items.clear();

    await _fetchItems(page: 1);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    if (_repo == null) return;

    setState(() => _isLoading = true);

    final nextPage = _page + 1;
    final ok = await _fetchItems(page: nextPage);
    if (ok) _page = nextPage;

    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool> _fetchItems({required int page}) async {
    final repo = _repo;
    if (repo == null) return false;

    final store = ThemeScope.of(context);

    try {
      final src = _factory.fromStore(store);
      repo.setSource(src);

      final newItems = await repo.search(
        SearchQuery(page: page, filters: _filters),
      );

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

  void _applyFilters(FilterSpec f) {
    setState(() => _filters = f);
    _persistFilters(f);
    _initData();
  }

  void _resetFilters() {
    setState(() => _filters = const FilterSpec());
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
                                item: item, // ← 就是这里
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