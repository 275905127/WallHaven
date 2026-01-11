import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'settings_page.dart'; // 导入设置页用于跳转
import 'filter_page.dart';
import 'image_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 模拟下拉刷新的逻辑
  Future<void> _handleRefresh() async {
    // 这里模拟网络请求延迟2秒
    await Future.delayed(const Duration(seconds: 2));
    // 刷新完成后，通常在这里更新数据并 setState
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
      // 【改动点1：移除了底部的 bottomNavigationBar】

      body: SafeArea(
        // 【改动点2：新增 RefreshIndicator 实现下拉刷新】
        // 它必须包裹住支持滚动的组件（这里是 CustomScrollView）
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.blue, // 刷新圈的颜色（配合主题色）
          backgroundColor: Colors.white, // 刷新圈背景
          edgeOffset: kToolbarHeight, // 让刷新圈出现在标题栏下方，体验更好

          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                title: const Text("Wallhaven"),
                // 【改动点3：全新的顶部右侧图标组】
                actions: [
                  // 1. 左边：搜索图标
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    tooltip: '搜索',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("点击了搜索")));
                    },
                  ),
                  // 2. 中间：筛选图标 (搭配合适的图标 filter_list 或 tune)
                  IconButton(
  icon: const Icon(Icons.filter_list_alt, size: 26),
  tooltip: '筛选',
  onPressed: () {
    // 跳转到筛选页
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterPage()),
    );
  },
),
                  // 3. 最右：设置图标
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26),
                    tooltip: '设置',
                    onPressed: () {
                      // 【改动点4：点击跳转到设置页】
                      // 使用 push 跳转，设置页会自动出现返回按钮
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    },
                  ),
                  const SizedBox(width: 12), // 右侧留点边距
                ],
              ),

              // 下面是原来的顶部大卡片和瀑布流，保持不变
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

  // (后面的辅助构建方法 _buildHeaderCard 和 _buildWallpaperItem 保持不变，这里省略，请保留原文件中的这些代码)
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

  Widget _buildWallpaperItem(int index) {
    final String imageUrl = 'https://picsum.photos/400/${(index % 3 + 2) * 100}?random=$index';
    final String heroTag = 'wallpaper_$index'; // 唯一的 tag

    return GestureDetector(
      // 点击跳转到详情页
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetailPage(
              imageUrl: imageUrl, // 把图片链接传过去
              heroTag: heroTag,   // 把动画标签传过去
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
              // 给图片加上 Hero 组件，实现转场动画
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
                    // 首页列表上的小收藏按钮（简单的视觉反馈）
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
}
