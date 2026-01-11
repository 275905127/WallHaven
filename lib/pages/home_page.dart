import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart'; // 必须导入 dio
import '../models/wallpaper.dart'; // 导入刚才建的模型
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
  int _page = 1; // 当前页码
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchWallpapers(); // 启动时加载
    
    // 监听滚动，到底部自动加载更多
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

  // 核心：请求 Wallhaven API
  Future<void> _fetchWallpapers({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _page = 1;
        _wallpapers.clear();
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 真实请求
      var response = await Dio().get(
        'https://wallhaven.cc/api/v1/search',
        queryParameters: {
          'page': _page,
          'sorting': 'date_added', // 默认按时间排序
          // 'apikey': '你的key', // 如果要在首页看限制级内容，后续要把 settings 里的 key 传进来
        },
      );

      if (response.statusCode == 200) {
        var dataList = response.data['data'] as List;
        List<Wallpaper> newWallpapers = dataList
            .map((json) => Wallpaper.fromJson(json))
            .toList();

        if (mounted) {
          setState(() {
            _wallpapers.addAll(newWallpapers);
            _page++; // 准备加载下一页
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("加载失败: $e")),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchWallpapers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.blue,
          backgroundColor: Colors.white,
          edgeOffset: kToolbarHeight,
          child: CustomScrollView(
            controller: _scrollController, // 绑定滚动控制器
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                title: const Text("Wallhaven"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_alt, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FilterPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26),
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

              // 真实的瀑布流列表
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
              
              // 底部加载指示器
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              
              // 底部留白
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  // 辅助组件：壁纸单项 (纯净版)
  Widget _buildWallpaperItem(Wallpaper wallpaper) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetailPage(
              // 传真实的 URL 进去
              imageUrl: wallpaper.fullSizeUrl, 
              heroTag: wallpaper.id,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200], // 占位背景色
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Hero(
            tag: wallpaper.id,
            child: Image.network(
              wallpaper.thumbUrl, // 列表页只加载缩略图，省流量且快
              fit: BoxFit.cover,
              // 加载过程中的渐变效果
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return AspectRatio(
                  aspectRatio: 0.7, // 预设一个比例防止抖动
                  child: Container(color: Colors.grey[200]),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
