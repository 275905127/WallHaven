import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'settings_page.dart'; // 关键：导入设置页

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 页面切换逻辑
    if (_selectedIndex == 2) {
      return const SettingsPage();
    }

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '搜索',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: true,
              title: const Text("Wallhaven"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, size: 28),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, size: 28),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
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
    );
  }

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Image.network(
              'https://picsum.photos/400/${(index % 3 + 2) * 100}?random=$index',
              fit: BoxFit.cover,
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
    );
  }
}
