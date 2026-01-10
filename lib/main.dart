import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallhaven Demo',
      // 设置全局暗黑主题，匹配你的截图风格
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black, // 纯黑背景
        useMaterial3: true,
        primaryColor: Colors.amber, // 强调色（黄色）
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: Colors.amber.withOpacity(0.6),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 底部导航栏当前选中的索引
  int _selectedIndex = 0;
  
  // 用于控制 FAB (悬浮按钮) 的显隐
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  // 模拟的分类标签数据
  final List<String> _tags = ["General", "Anime", "People", "Cyberpunk", "City", "Cars", "Art"];

  @override
  void initState() {
    super.initState();
    // 监听滚动，向下滚动时隐藏 FAB，向上滚动显示
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isFabVisible) setState(() => _isFabVisible = false);
      } else {
        if (!_isFabVisible) setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==========================================
      // 3. 悬浮功能按钮 (FAB)
      // ==========================================
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2), // 隐藏时向下移动
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: () {
              // 点击回到顶部
              _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
            },
            backgroundColor: Colors.amber, // 醒目的黄色
            child: const Icon(Icons.arrow_upward, color: Colors.black),
          ),
        ),
      ),

      // ==========================================
      // 4. 底部导航栏
      // ==========================================
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
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Category',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
        ],
      ),

      // 使用 CustomScrollView 实现复杂的组合滚动效果
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ==========================================
          // 1. 顶部区域：标题 + 搜索 (Search)
          // ==========================================
          SliverAppBar(
            floating: true, // 向下滑动时，搜索栏会立即出现
            snap: true,     // 配合 floating 使用
            pinned: false,  // 不一直固定在顶部，节省空间看图
            backgroundColor: Colors.black,
            title: const Text("Wallhaven", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // 这里处理点击搜索的逻辑
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("打开搜索页面")));
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ==========================================
          // 2. 筛选/分类标签 (Filters/Tags)
          // ==========================================
          SliverToBoxAdapter(
            child: Container(
              height: 60, // 标签栏高度
              color: Colors.black,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  // 第一个默认选中（模拟）
                  final isSelected = index == 1; 
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(tag),
                      selected: isSelected,
                      checkmarkColor: Colors.black,
                      selectedColor: Colors.amber, // 选中变黄
                      backgroundColor: Colors.grey[900], // 未选中深灰
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (bool value) {},
                    ),
                  );
                },
              ),
            ),
          ),

          // ==========================================
          // 中间内容：瀑布流图片列表
          // ==========================================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2, // 两列
              mainAxisSpacing: 8, // 上下间距
              crossAxisSpacing: 8, // 左右间距
              childCount: 20, // 模拟20张图
              itemBuilder: (context, index) {
                // 模拟不同高度的图片
                final height = (index % 3 + 2) * 100.0; 
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[900], // 图片加载前的占位色
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // 使用网络图片 (Picsum 随机图)
                        Image.network(
                          'https://picsum.photos/400/${height.toInt()}?random=$index',
                          fit: BoxFit.cover,
                        ),
                        // 图片上的渐变文字保护层（类似截图里的效果）
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ==========================================
          // 5. 底部加载提示 (Loading Indicator)
          // ==========================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amber, // 加载圈也是黄色
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}