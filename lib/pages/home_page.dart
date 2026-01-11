import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart'; // 引入 Provider

// 引入你的内部文件
import '../models/wallpaper.dart';
import '../providers.dart'; // 引入刚才写的全局状态管理
import 'settings_page.dart';
import 'filter_page.dart';
import 'image_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 数据源
  final List<Wallpaper> _wallpapers = [];
  
  // 状态控制
  bool _isLoading = false;
  int _page = 1; 
  final ScrollController _scrollController = ScrollController();
  
  // 用来记录当前加载的是哪个图源，以便检测变化
  String? _lastSourceUrl;

  @override
  void initState() {
    super.initState();
    // 初始加载
    // 注意：initState 里不能直接用 context.read，需要加一个延时
    Future.microtask(() => _fetchWallpapers());
    
    // 监听滚动，触底加载更多
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchWallpapers();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 核心：请求 Wallhaven API (支持多图源)
  Future<void> _fetchWallpapers({bool refresh = false}) async {
    if (_isLoading) return;

    // 获取全局状态 (不监听变化，只读取一次)
    final appState = context.read<AppState>();
    final currentSource = appState.currentSource;

    // 如果是下拉刷新，或者检测到图源切换了，重置列表
    if (refresh || _lastSourceUrl != currentSource.baseUrl) {
      setState(() {
        _page = 1;
        _wallpapers.clear();
        _lastSourceUrl = currentSource.baseUrl; // 更新记录
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 准备参数
      final queryParams = {
        'page': _page,
        'sorting': 'date_added',
        // 2. 合并图源自带的参数 (例如动漫源自带 categories: 010)
        ...currentSource.params,
        // 这里后续还可以合并 FilterPage 里的筛选参数
      };

      // 3. 发起真实请求
      var response = await Dio().get(
        currentSource.baseUrl,
        queryParameters: queryParams,
      );

      // 4. 解析数据
      if (response.statusCode == 200) {
        var dataList = response.data['data'] as List;
        List<Wallpaper> newWallpapers = dataList
            .map((json) => Wallpaper.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _wallpapers.addAll(newWallpapers);
            _page++; // 准备下一页
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // 简单的错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("加载失败，请检查网络: $e")),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchWallpapers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局状态：如果语言变了，或者主题变了，这里会重绘
    final appState = context.watch<AppState>();

    // 检测：如果从设置页回来，发现图源变了，但列表还没空，自动刷新一下
    if (_lastSourceUrl != null && _lastSourceUrl != appState.currentSource.baseUrl) {
       // 这里做一个延迟刷新，避免构建时setState报错
       Future.microtask(() => _fetchWallpapers(refresh: true));
    }

    // 根据语言显示不同的提示
    final isZh = appState.locale.languageCode == 'zh';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          // 使用主题色作为刷新指示器颜色
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          edgeOffset: kToolbarHeight,
          
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: false, // 跟随滑动隐藏
                floating: true, // 下拉即出现
                // 标题显示当前图源名称，不仅好看，还能让用户知道自己在看哪里
                title: Text(appState.currentSource.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    tooltip: isZh ? '搜索' : 'Search',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text(isZh ? "搜索功能开发中..." : "Search coming soon...")),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_alt, size: 26),
                    tooltip: isZh ? '筛选' : 'Filter',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FilterPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26),
                    tooltip: isZh ? '设置' : 'Settings',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                ],
              ),

              // 瀑布流列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: _wallpapers.length,
                  itemBuilder: (context, index) {
                    return _buildWallpaperItem(_wallpapers[index]);
                  },
                ),
              ),
              
              // 底部加载 Loading
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              
              // 底部安全留白
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  // 辅助组件：单张壁纸卡片 (纯净版 - 无底栏)
  Widget _buildWallpaperItem(Wallpaper wallpaper) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetailPage(
              imageUrl: wallpaper.fullSizeUrl, // 传入原图地址
              heroTag: wallpaper.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 占位色：使用当前主题的 surfaceContainerHighest 颜色，适配深色模式
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Hero(
            tag: wallpaper.id,
            child: Image.network(
              wallpaper.thumbUrl, // 列表只显示缩略图
              fit: BoxFit.cover,
              // 加载过程优化
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return AspectRatio(
                  aspectRatio: 0.7, // 预设比例，防止图片跳动
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: SizedBox(
                        width: 20, height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.white54),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
