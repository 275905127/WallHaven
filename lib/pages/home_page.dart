import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../models/wallpaper.dart';
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
    final activeParams = appState.activeParams;
    
    String currentHash = "${currentSource.baseUrl}|${activeParams.toString()}";

    if (refresh || _lastSourceHash != currentHash) {
      setState(() {
        _page = 1;
        _wallpapers.clear();
        _lastSourceHash = currentHash;
      });
    }

    setState(() => _isLoading = true);

    // === 直链模式 (Luvbree 等随机图) ===
    if (currentSource.listKey == '@direct') {
      int batchSize = 10; 
      for (int i = 0; i < batchSize; i++) {
        if (!mounted) return;

        final randomId = Random().nextInt(1000000);
        final separator = currentSource.baseUrl.contains('?') ? '&' : '?';
        final directUrl = "${currentSource.baseUrl}${separator}_r=${_page}_${i}_$randomId";

        // 【优化】给随机图生成一个随机宽高比 (0.6 ~ 1.6)
        // 这样即使图还没出来，瀑布流也是错落有致的，不会全是正方形
        double randomRatio = 0.6 + Random().nextDouble(); 

        final newItem = Wallpaper(
          id: "direct_${_page}_${i}_$randomId",
          thumbUrl: directUrl,
          fullSizeUrl: directUrl,
          resolution: "Random",
          views: 0,
          favorites: 0,
          aspectRatio: randomRatio, // 使用随机比例占位
        );

        if (mounted) {
          setState(() {
            _wallpapers.add(newItem);
          });
        }
        await Future.delayed(const Duration(milliseconds: 300)); // 适当加快一点点
      }

      if (mounted) {
        setState(() {
          _page++;
          _isLoading = false;
        });
      }
      return; 
    }

    // === 普通 API 模式 (Wallhaven 等) ===
    try {
      final Map<String, dynamic> queryParams = {
        'page': _page,
        if (currentSource.apiKey.isNotEmpty) 
          currentSource.apiKeyParam: currentSource.apiKey,
      };

      queryParams.addAll(activeParams);

      var response = await Dio().get(
        currentSource.baseUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        var rawData = _getValueByPath(response.data, currentSource.listKey);
        
        List listData = [];
        if (rawData is List) {
          listData = rawData;
        } else if (rawData is Map) {
          listData = [rawData];
        }

        if (listData.isNotEmpty) {
          List<Wallpaper> newWallpapers = listData.map((item) {
            String thumb = _getValueByPath(item, currentSource.thumbKey) ?? "";
            String full = _getValueByPath(item, currentSource.fullKey) ?? thumb;
            String id = _getValueByPath(item, currentSource.idKey)?.toString() ?? full.hashCode.toString();
            
            // 【核心优化】尝试解析宽高，计算比例
            double ratio = 1.0;
            try {
              // Wallhaven 字段: dimension_x, dimension_y
              // 其他源可能是 width, height，这里做一个简单的容错读取
              // 如果你的源 key 不一样，这里可能需要去 SourceConfig 里加配置，但 dimension_x 是 Wallhaven 标配
              var w = item['dimension_x'] ?? item['width'];
              var h = item['dimension_y'] ?? item['height'];
              if (w != null && h != null) {
                ratio = (w as num) / (h as num);
              } else if (item['ratio'] != null) {
                // 有些 API 直接返回 "1.77"
                ratio = double.tryParse(item['ratio'].toString()) ?? 1.0;
              }
            } catch (e) {
              ratio = 1.0;
            }

            return Wallpaper(
              id: id,
              thumbUrl: thumb,
              fullSizeUrl: full,
              resolution: "",
              views: 0,
              favorites: 0,
              aspectRatio: ratio, // 存入比例
            );
          }).where((w) => w.thumbUrl.isNotEmpty).toList();

          if (mounted) {
            setState(() {
              _wallpapers.addAll(newWallpapers);
              _page++;
              _isLoading = false;
            });
          }
        } else {
           if (mounted) setState(() => _isLoading = false);
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

    if (_lastSourceHash != null && 
        _lastSourceHash != "${appState.currentSource.baseUrl}|${appState.activeParams.toString()}") {
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
                    icon: const Icon(Icons.filter_list_alt, size: 26),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FilterPage()));
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest, // 占位背景色
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          // 【核心优化】使用 AspectRatio 提前占位
          child: AspectRatio(
            aspectRatio: wallpaper.aspectRatio,
            child: Hero(
              tag: wallpaper.id,
              child: Image.network(
                wallpaper.thumbUrl,
                fit: BoxFit.cover,
                // 加载中不显示 Loading 转圈了，因为背景色已经占位了，看起来更干净
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.transparent); // 透明，透出底部的卡片色
                },
                errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
