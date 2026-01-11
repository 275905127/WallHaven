import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../providers.dart';
import 'filter_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _wallpapers = [];
  bool _isLoading = false;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();
  
  // 用于记录上次的筛选参数，对比是否有变动
  String _lastParamsHash = "";

  @override
  void initState() {
    super.initState();
    _fetchWallpapers();
    _scrollController.addListener(_onScroll);
  }

  // 核心逻辑：从筛选页回来时，如果参数变了就自动刷新
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.watch<AppState>();
    final currentHash = jsonEncode(appState.activeParams);
    
    if (_lastParamsHash.isNotEmpty && _lastParamsHash != currentHash) {
      _lastParamsHash = currentHash;
      _refresh();
    } else {
      _lastParamsHash = currentHash;
    }
  }

  Future<void> _fetchWallpapers({bool isRefresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (isRefresh) {
      _page = 1;
      _wallpapers.clear();
    }

    final appState = context.read<AppState>();
    final source = appState.currentSource;
    
    // 构建请求 URL
    Map<String, String> queryParams = {
      'page': _page.toString(),
      if (source.apiKey.isNotEmpty) 'apikey': source.apiKey,
    };
    
    // 合并筛选参数
    appState.activeParams.forEach((key, value) {
      if (value.toString().isNotEmpty) queryParams[key] = value.toString();
    });

    final uri = Uri.parse(source.baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _wallpapers.addAll(data['data']);
          _page++;
        });
      }
    } catch (e) {
      debugPrint("加载失败: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _fetchWallpapers();
    }
  }

  Future<void> _refresh() async {
    await _fetchWallpapers(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: const Text("Wallpapers", style: TextStyle(fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FilterPage())),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              child: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemBuilder: (context, index) {
                  return _buildWallpaperItem(_wallpapers[index]);
                },
                childCount: _wallpapers.length,
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallpaperItem(dynamic wallpaper) {
    // 获取比例，防止瀑布流跳动
    double ratio = (wallpaper['dimension_x'] ?? 100) / (wallpaper['dimension_y'] ?? 150);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: ratio,
        child: Image.network(
          wallpaper['thumbs']['large'] ?? wallpaper['thumbs']['original'],
          fit: BoxFit.cover,
          // ✨ 复刻亮点：加载过程中的淡入动画
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: const Color(0xFFF1F1F3),
              child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 20)),
            );
          },
        ),
      ),
    );
  }
}
