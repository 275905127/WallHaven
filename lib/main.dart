import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // 瀑布流依赖
import 'package:cached_network_image/cached_network_image.dart'; // 图片缓存依赖

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_store.dart';
import 'widgets/foggy_app_bar.dart';
import 'widgets/settings_widgets.dart';
import 'pages/sub_pages.dart';
import 'models/wallpaper.dart'; // 引入模型
import 'api/wallhaven_api.dart'; // 引入API

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: store.mode,
      theme: AppTheme.light(store.accentColor, customBg: store.customBackgroundColor, customCard: store.customCardColor),
      darkTheme: AppTheme.dark(store.accentColor, customBg: store.customBackgroundColor, customCard: store.customCardColor),
      home: const HomePage(),
    );
  }
}

// ==========================================
// 🏠 首页 (瀑布流 + 雾化栏)
// ==========================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  
  // 数据状态
  final List<Wallpaper> _wallpapers = [];
  int _page = 1;
  bool _isLoading = false;
  bool _isScrolled = false; // 控制雾化

  @override
  void initState() {
    super.initState();
    _initData();
    
    // 监听滚动：1.控制雾化 2.触底加载
    _scrollController.addListener(() {
      // 1. 雾化控制
      if (_scrollController.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }

      // 2. 触底加载 (预加载 200px)
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  // 初始化数据
  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _fetchWallpapers();
    setState(() => _isLoading = false);
  }

  // 加载更多
  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _page++;
    await _fetchWallpapers();
    setState(() => _isLoading = false);
  }

  // 核心请求逻辑
  Future<void> _fetchWallpapers() async {
    final store = ThemeScope.of(context); // 获取全局状态 (图源信息)
    
    final newItems = await WallhavenApi.getWallpapers(
      baseUrl: store.currentSource.baseUrl,
      apiKey: store.currentSource.apiKey,
      page: _page,
    );

    if (mounted) {
      setState(() {
        _wallpapers.addAll(newItems);
      });
    }
  }

  // 刷新逻辑
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
      extendBodyBehindAppBar: true, // 让瀑布流冲到状态栏下面
      
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
          ? const Center(child: CircularProgressIndicator()) // 首次加载 loading
          : RefreshIndicator(
              onRefresh: _onRefresh,
              edgeOffset: 100, // 避开标题栏
              child: MasonryGridView.count(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 100, 12, 20), // 顶部留出标题栏高度
                crossAxisCount: 2, // 双列
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: _wallpapers.length,
                itemBuilder: (context, index) {
                  final paper = _wallpapers[index];
                  // 计算图片高度比例，防止跳动
                  final double aspectRatio = (paper.width / paper.height).clamp(0.5, 2.0);

                  return GestureDetector(
                    onTap: () {
                      // TODO: 点击进入详情页
                      print("Clicked: ${paper.id}");
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        // 🌟 修改点：这里改为读取 imageRadius (首页图片圆角)
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

// ==========================================
// ⚙️ 设置页 (主页)
// ==========================================
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

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final store = ThemeScope.of(context);
        ThemeMode tempMode = store.mode;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("外观"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRadio(context, "系统 (默认)", ThemeMode.system, tempMode, (v) => setState(() => tempMode = v!)),
                  _buildRadio(context, "浅色", ThemeMode.light, tempMode, (v) => setState(() => tempMode = v!)),
                  _buildRadio(context, "深色", ThemeMode.dark, tempMode, (v) => setState(() => tempMode = v!)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () { 
                    store.setMode(tempMode); 
                    Navigator.pop(context); 
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadio(BuildContext ctx, String title, ThemeMode val, ThemeMode group, ValueChanged<ThemeMode?> change) {
    return RadioListTile<ThemeMode>(
      title: Text(title), value: val, groupValue: group, onChanged: change,
      activeColor: Theme.of(ctx).colorScheme.primary, contentPadding: EdgeInsets.zero,
    );
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

  String _getModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "系统 (默认)";
      case ThemeMode.light: return "浅色";
      case ThemeMode.dark: return "深色";
    }
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
               subtitle: "自定义圆角与颜色", // 更新副标题
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalizationPage())),
             ),
             SettingsItem(
               icon: Icons.wb_sunny_outlined, 
               title: "主题", 
               subtitle: _getModeName(store.mode),
               onTap: () => _showAppearanceDialog(context)
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
