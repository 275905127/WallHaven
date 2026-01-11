import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../models/wallpaper.dart'; // 我们依然用这个模型来承载最终显示的图片
import '../models/source_config.dart'; // 新的配置模型
import '../providers.dart';
import 'settings_page.dart';
import 'filter_page.dart';
import 'image_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Wallpaper> _wallpapers = [];
  bool _isLoading = false;
  int _page = 1; 
  final ScrollController _scrollController = ScrollController();
  
  // 记录上次请求的 URL 以检测变化
  String? _lastSourceHash;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchWallpapers());
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

  // --- 通用 JSON 解析器 ---
  // 比如传入 obj, "thumbs.large" -> 返回 obj['thumbs']['large']
  dynamic _getValueByPath(dynamic json, String path) {
    if (path.isEmpty) return json;
    List<String> keys = path.split('.');
    dynamic current = json;
    for (String key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  Future<void> _fetchWallpapers({bool refresh = false}) async {
    if (_isLoading) return;

    final appState = context.read<AppState>();
    final currentSource = appState.currentSource;
    // 获取所有动态参数
    final activeParams = appState.activeParams;
    
    // Hash 判断逻辑，防止重复请求
    String currentHash = "${currentSource.baseUrl}|${activeParams.toString()}";

    if (refresh || _lastSourceHash != currentHash) {
      setState(() {
        _page = 1;
        _wallpapers.clear();
        _lastSourceHash = currentHash;
      });
    }

    setState(() => _isLoading = true);

    try {
      // 1. 基础参数
      final queryParams = {
        'page': _page,
        if (currentSource.apiKey.isNotEmpty) 
          currentSource.apiKeyParam: currentSource.apiKey,
      };

      // 2. 【关键】合并动态筛选参数
      // 这里的 activeParams 里面现在包含了 "sorting", "categories" 等由 FilterPage 动态生成的值
      queryParams.addAll(activeParams);

      // 3. 发起请求
      var response = await Dio().get(
        currentSource.baseUrl,
        queryParameters: queryParams,
      );
      
      // ... (后续解析代码保持不变) ...

      // 3. 通用解析
      if (response.statusCode == 200) {
        // 根据配置的 listKey 找到数组 (例如 'data' 或 'hits')
        var rawList = _getValueByPath(response.data, currentSource.listKey);
        
        if (rawList is List) {
          List<Wallpaper> newWallpapers = rawList.map((item) {
            // 根据配置的 key 动态取值
            String thumb = _getValueByPath(item, currentSource.thumbKey) ?? "";
            String full = _getValueByPath(item, currentSource.fullKey) ?? thumb;
            String id = _getValueByPath(item, currentSource.idKey).toString();

            return Wallpaper(
              id: id,
              thumbUrl: thumb,
              fullSizeUrl: full,
              resolution: "", // 可选
              views: 0,       // 可选
              favorites: 0,   // 可选
            );
          }).where((w) => w.thumbUrl.isNotEmpty).toList(); // 过滤掉无效数据

          if (mounted) {
            setState(() {
              _wallpapers.addAll(newWallpapers);
              _page++;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Load Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchWallpapers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 自动刷新逻辑
    if (_lastSourceHash != null && 
        _lastSourceHash != "${appState.currentSource.baseUrl}|${appState.activeFilters['q']}") {
       Future.microtask(() => _fetchWallpapers(refresh: true));
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                title: Text(appState.currentSource.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 26),
                    onPressed: () async {
                      final query = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final ctrl = TextEditingController();
                          return AlertDialog(
                            content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: "Search...")),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("Go"))],
                          );
                        }
                      );
                      if (query != null) context.read<AppState>().updateSearchQuery(query);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 26),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                    },
                  ),
                  const SizedBox(width: 12),
                ],
              ),

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
              
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperItem(Wallpaper wallpaper) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ImageDetailPage(imageUrl: wallpaper.fullSizeUrl, heroTag: wallpaper.id)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Hero(
            tag: wallpaper.id,
            child: Image.network(
              wallpaper.thumbUrl,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => const SizedBox(height: 150, child: Icon(Icons.broken_image)),
            ),
          ),
        ),
      ),
    );
  }
}
