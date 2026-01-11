import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'settings_page.dart';
import 'filter_page.dart';
import 'image_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 模拟下拉刷新
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('刷新完成')),
      );
    }
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
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                title: const Text("Wallhaven"),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    tooltip: '搜索',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("点击了搜索")));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_alt, size: 26),
                    tooltip: '筛选',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FilterPage()),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26),
                    tooltip: '设置',
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

              // 【改动点】：去掉了顶部的 SliverToBoxAdapter（两个大卡片）

              // 瀑布流列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: 20,
                  itemBuilder: (context, index) {
                    return _buildWallpaperItem(index);
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  // 辅助组件：壁纸单项 (纯图片模式)
  Widget _buildWallpaperItem(int index) {
    final String imageUrl = 'https://picsum.photos/400/${(index % 3 + 2) * 100}?random=$index';
    final String heroTag = 'wallpaper_$index';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetailPage(
              imageUrl: imageUrl,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        // 【改动点】：ClipRRect 下直接包裹 Hero -> Image，去掉了下方的文字介绍 Row
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
