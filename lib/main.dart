// lib/main.dart
// ⚠️ 警示：此文件是入口与交互基线，禁止随意挪动 Widget 树导致主题/左侧右滑筛选失效。
// ⚠️ 警示：筛选手势体验优先；不要强行加花色图标和高饱和颜色。

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'theme/app_theme.dart';
import 'theme/theme_store.dart';
import 'widgets/foggy_app_bar.dart';
import 'widgets/settings_widgets.dart';
import 'pages/sub_pages.dart';
import 'pages/filter_drawer.dart';
import 'pages/wallpaper_detail_page.dart';
import 'models/wallpaper.dart';

// ✅ 最终版：业务层只依赖“统一 client 接口”，不认识 WallhavenClient
import 'sources/source_plugin.dart';

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
  final List<Wallpaper> _wallpapers = [];
  int _page = 1;
  bool _isLoading = false;
  bool _isScrolled = false;

  bool _drawerOpen = false;

  // ✅ 用于检测“切源”并自动刷新
  String? _lastSourceConfigId;

  // ✅ 复用 Dio，避免每次请求都 new 一个
  final Dio _dio = Dio();

  WallhavenFilters _filters = const WallhavenFilters();

  @override
  void initState() {
    super.initState();
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
    _wallpapers.clear();

    // ✅ 删掉 ok / (void)ok; —— 这就是你 CI 里 record/重复声明那坨屎的来源
    await _fetchWallpapers(page: 1);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final nextPage = _page + 1;
    final ok2 = await _fetchWallpapers(page: nextPage);

    // ✅ 只有成功才提交页码，避免失败跳页
    if (ok2) _page = nextPage;

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ 最终版：业务层只拿 “统一 client”
  Future<bool> _fetchWallpapers({required int page}) async {
    final store = ThemeScope.of(context);
    final f = _filters;

    try {
      final plugin = store.currentPlugin;
      if (plugin == null) {
        throw StateError('No current plugin for sourceConfig=${store.currentSourceConfig.id}');
      }

      // ✅ 关键修复：你这里写的 store.currentSettings 在 ThemeStore 里很可能根本不存在
      // 用你 ThemeStore 已经暴露的：currentPluginSettings（或直接 currentSourceConfig.settings）
      final Map<String, dynamic> settings =
          (store.currentPluginSettings); // 或者：Map<String, dynamic>.from(store.currentSourceConfig.settings)

      final WallpaperSourceClient client = plugin.createClient(
        settings: settings,
        dio: _dio,
      );

      // 现在 drawer/filter 仍是 WallhavenFilters，所以这里仍然组 Wallhaven 参数
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

      final newItems = await client.search(
        page: page,
        params: params,
      );

      if (!mounted) return false;
      setState(() => _wallpapers.addAll(newItems));
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
    _dio.close(force: true);
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

        // ✅ 切源自动刷新：避免“切了源但列表还是旧的”
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
            body: _wallpapers.isEmpty && _isLoading
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
                      itemCount: _wallpapers.length,
                      itemBuilder: (context, index) {
                        final paper = _wallpapers[index];
                        final double aspectRatio = (paper.width / paper.height).clamp(0.5, 2.0);

                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WallpaperDetailPage(
                                id: paper.id,
                                heroThumb: paper.thumb,
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
                                imageUrl: paper.thumb,
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _sc = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_sc.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void _showSourceSelectionDialog(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("切换图源"),
        children: store.sourceConfigs.map((cfg) {
          final isCurrent = store.currentSourceConfig.id == cfg.id;
          return SimpleDialogOption(
            onPressed: () {
              store.setCurrentSourceConfig(cfg.id);
              Navigator.pop(context);
            },
            child: Row(
              children: [
                Icon(cfg.id.startsWith('default_') ? Icons.verified : Icons.link, color: theme.iconTheme.color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(cfg.name, style: const TextStyle(fontSize: 16))),
                if (isCurrent) Icon(Icons.check, color: theme.iconTheme.color),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final topPadding = MediaQuery.of(context).padding.top + 96;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: FoggyAppBar(
            title: const Text('设置'),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            isScrolled: _isScrolled,
            fogStrength: 1.0,
          ),
          body: ListView(
            controller: _sc,
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
            children: [
              const UserProfileHeader(),
              const SizedBox(height: 32),
              const SectionHeader(title: "外观"),
              SettingsGroup(items: [
                SettingsItem(
                  icon: Icons.person_outline,
                  title: "个性化",
                  subtitle: "自定义圆角与颜色",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalizationPage())),
                ),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(title: "图源"),
              SettingsGroup(items: [
                SettingsItem(
                  icon: Icons.swap_horiz,
                  title: "切换图源",
                  subtitle: store.currentSourceConfig.name,
                  onTap: () => _showSourceSelectionDialog(context),
                ),
                SettingsItem(
                  icon: Icons.settings_ethernet,
                  title: "图源管理",
                  subtitle: "添加或管理第三方源",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SourceManagementPage())),
                ),
              ]),
              const SizedBox(height: 300),
            ],
          ),
        );
      },
    );
  }
}

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFD2AE00), shape: BoxShape.circle),
          child: Text(
            "27",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black.withOpacity(0.7),
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "星河 於长野",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}