import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_store.dart';
import 'widgets/foggy_app_bar.dart';
import 'widgets/settings_widgets.dart';
import 'pages/sub_pages.dart';
import 'models/wallpaper.dart';
import 'api/wallhaven_api.dart';

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
    
    // 自定义颜色逻辑
    final customBg = store.enableCustomColors ? store.customBackgroundColor : null;
    final customCard = store.enableCustomColors ? store.customCardColor : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: store.mode,
      // 🌟 核心修改：将 store.cardRadius 传入主题配置
      theme: AppTheme.light(
        store.accentColor, 
        customBg: customBg, 
        customCard: customCard, 
        cardRadius: store.cardRadius, // 传入圆角
      ),
      darkTheme: AppTheme.dark(
        store.accentColor, 
        customBg: customBg, 
        customCard: customCard,
        cardRadius: store.cardRadius, // 传入圆角
      ),
      home: const HomePage(),
    );
  }
}

// ... 下面的 HomePage 等代码保持不变 ...
// (为了节省篇幅，请保留你现有的 HomePage 代码，无需改动)
// ==========================================
// 🏠 首页 (HomePage) - 保持不变
// ==========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final List<Wallpaper> _wallpapers = [];
  int _page = 1;
  bool _isLoading = false;
  bool _isScrolled = false; 

  @override
  void initState() {
    super.initState();
    _initData();
    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_scrollController.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMore();
    });
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _fetchWallpapers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _page++;
    await _fetchWallpapers();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchWallpapers() async {
    final store = ThemeScope.of(context);
    final newItems = await WallhavenApi.getWallpapers(
      baseUrl: store.currentSource.baseUrl,
      apiKey: store.currentSource.apiKey,
      page: _page,
    );
    if (mounted) setState(() => _wallpapers.addAll(newItems));
  }

  Future<void> _onRefresh() async {
    _page = 1;
    _wallpapers.clear();
    await _initData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(
        title: const Text("Wallhaven Pro"),
        isScrolled: _isScrolled,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
          ),
          const SizedBox(width: 8),
        ],
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
                    onTap: () { print("Clicked: ${paper.id}"); },
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
                          placeholder: (context, url) => Container(color: theme.cardColor, child: const Center(child: Icon(Icons.image, color: Colors.grey))),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ⚙️ SettingsPage 和 SubPages 保持不变
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

  void _showSourceSelectionDialog(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("切换图源"),
        children: store.sources.map((source) {
          return SimpleDialogOption(
            onPressed: () { store.setSource(source); Navigator.pop(context); },
            child: Row(
              children: [
                Icon(source.isBuiltIn ? Icons.verified : Icons.link, color: theme.iconTheme.color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(source.name, style: const TextStyle(fontSize: 16))),
                if (store.currentSource.id == source.id) Icon(Icons.check, color: store.accentColor),
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
    final topPadding = MediaQuery.of(context).padding.top + 96;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(title: const Text('设置'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), isScrolled: _isScrolled),
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
               subtitle: store.currentSource.name,
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
          width: 80, height: 80, 
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
          child: Text("27", style: TextStyle(color: isDark ? Colors.white : Colors.black.withOpacity(0.7), fontSize: 32, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 16),
        Text("星河 於长野", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
