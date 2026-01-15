// lib/main.dart
import 'dart:convert';
import 'domain/entities/filter_spec.dart';
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

import 'pages/wallpaper_detail_page.dart';

// ✅ domain/data
import 'domain/entities/search_query.dart';
import 'domain/entities/wallpaper_item.dart';
import 'domain/search/query_spec.dart';

import 'data/http/http_client.dart';
import 'data/repository/wallpaper_repository.dart';
import 'data/source_factory.dart';
import 'data/query_adapters/wallhaven_query_adapter.dart';
import 'data/query_adapters/generic_query_adapter.dart';

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
  // ✅ 改：不再叫 wallhaven_filters_v1
  static const String _kQueryPrefsKey = 'query_spec_v1';

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
  late final WallpaperRepository _repo;

  // ✅ 改：Domain Query
  QuerySpec _query = const QuerySpec();

  @override
  void initState() {
    super.initState();

    _http = HttpClient();
    _factory = SourceFactory(http: _http);

    // 临时占位：第一次 fetch 会 setSource
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
    await _loadPersistedQuery();
    if (!mounted) return;
    await _initData();
  }

  // =========================
  // ✅ QuerySpec 持久化
  // =========================

  Future<void> _loadPersistedQuery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kQueryPrefsKey);
      if (raw == null || raw.trim().isEmpty) return;

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final m = decoded.cast<String, dynamic>();

      QuerySpec next = const QuerySpec();

      // text
      final text = (m['text'] as String?) ?? '';
      next = next.copyWith(text: text);

      // sort/order
      next = next.copyWith(
        sort: _parseSortKey(m['sort'] as String?) ?? next.sort,
        order: _parseSortOrder(m['order'] as String?) ?? next.order,
      );

      // categories/ratings
      next = next.copyWith(
        categories: _parseEnumSet<Category>(m['categories'], Category.values, Category.general),
        ratings: _parseEnumSet<Rating>(m['ratings'], Rating.values, Rating.sfw),
      );

      // sets
      next = next.copyWith(
        resolutions: _parseStringSet(m['resolutions']),
        ratios: _parseStringSet(m['ratios']),
      );

      // scalars
      next = next.copyWith(
        atleast: (m['atleast'] as String?) ?? '',
        colorHex: (m['colorHex'] as String?) ?? '',
        toplistRange: (m['toplistRange'] as String?) ?? next.toplistRange,
      );

      if (!mounted) return;
      setState(() => _query = next);
    } catch (_) {}
  }

  Future<void> _persistQuery(QuerySpec q) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{
        'text': q.text,
        'sort': q.sort.name,
        'order': q.order.name,
        'categories': q.categories.map((e) => e.name).toList(),
        'ratings': q.ratings.map((e) => e.name).toList(),
        'resolutions': q.resolutions.toList()..sort(),
        'ratios': q.ratios.toList()..sort(),
        'atleast': q.atleast,
        'colorHex': q.colorHex,
        'toplistRange': q.toplistRange,
      };
      await prefs.setString(_kQueryPrefsKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _clearPersistedQuery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kQueryPrefsKey);
    } catch (_) {}
  }

  // =========================
  // Data loading
  // =========================

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

    try {
      // 切源：repo 只负责 search；源选择交给 factory
      final src = _factory.fromStore(store);
      _repo.setSource(src);

      // ✅ 关键：由 adapter 翻译参数，UI 不知道 wallhaven 参数长什么样
      final Map<String, dynamic> params = (src.pluginId == 'wallhaven')
          ? WallhavenQueryAdapter.toParams(_query)
          : GenericQueryAdapter.toParams(_query);

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

  void _applyQuery(QuerySpec q) {
    setState(() => _query = q);
    _persistQuery(q);
    _initData();
  }

  void _resetQuery() {
    setState(() => _query = const QuerySpec());
    _clearPersistedQuery();
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

        // 切源自动刷新
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
                initial: _query,
                onApply: _applyQuery,
                onReset: _resetQuery,
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

// ====== 持久化解析 helpers ======

SortKey? _parseSortKey(String? s) {
  if (s == null) return null;
  for (final v in SortKey.values) {
    if (v.name == s) return v;
  }
  return null;
}

SortOrder? _parseSortOrder(String? s) {
  if (s == null) return null;
  for (final v in SortOrder.values) {
    if (v.name == s) return v;
  }
  return null;
}

Set<String> _parseStringSet(dynamic v) {
  if (v is List) return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toSet();
  if (v is String && v.trim().isNotEmpty) return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  return <String>{};
}

Set<T> _parseEnumSet<T>(dynamic v, List<T> values, T fallback) {
  if (v is List) {
    final set = <T>{};
    for (final e in v) {
      final name = e?.toString();
      if (name == null) continue;
      final match = values.firstWhere(
        (x) => (x as dynamic).name == name,
        orElse: () => fallback,
      );
      set.add(match);
    }
    return set.isEmpty ? {fallback} : set;
  }
  return {fallback};
}