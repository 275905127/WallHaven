import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'settings_page.dart'; // 导入设置页
import 'filter_page.dart';   // 导入筛选页
import 'image_detail_page.dart'; // 导入图片详情页

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 模拟下拉刷新的逻辑
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        // 数据更新逻辑...
      });
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
                  // 1. 搜索
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    tooltip: '搜索',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("点击了搜索")));
                    },
                  ),
                  // 2. 筛选
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
                  // 3. 设置
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

              // 顶部大卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildHeaderCard(
                          title: "最新壁纸",
                          subtitle: "Latest",
                          icon: Icons.image_outlined,
                          code: "NEW",
                          color: Colors.blue.shade50,
                          textColor: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderCard(
                          title: "排行榜",
                          subtitle: "Toplist",
                          icon: Icons.leaderboard_outlined,
                          code: "TOP",
                          color: Colors.orange.shade50,
                          textColor: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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

  // 辅助组件：顶部卡片
  Widget _buildHeaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String code,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  // 辅助组件：壁纸单项 (包含点击跳转和 Hero 动画)
  Widget _buildWallpaperItem(int index) {
    // 构造图片地址
    final String imageUrl = 'https://picsum.photos/400/${(index % 3 + 2) * 100}?random=$index';
    // 构造唯一的 Hero 标签
    final String heroTag = 'wallpaper_$index';

    return GestureDetector(
      // 点击跳转逻辑
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Hero 动画组件
              Hero(
                tag: heroTag,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("${index * 99}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
} // <--- 之前可能就是少了这一个大括号！
