import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  bool _hasMore = true;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();
  
  String? _lastSourceHash;
  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchWallpapers());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchWallpapers();
    }
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

    if (!refresh && DateTime.now().difference(_lastFetchTime).inSeconds < 1) {
      return;
    }
    _lastFetchTime = DateTime.now();

    final appState = context.read<AppState>();
    final currentSource = appState.currentSource;
    final activeParams = appState.activeParams;
    
    String currentHash = "${currentSource.baseUrl}|${activeParams.toString()}";

    if (refresh || _lastSourceHash != currentHash) {
      if (mounted) {
        setState(() {
          _page = 1;
          _wallpapers.clear();
          _lastSourceHash = currentHash;
          _hasMore = true;
        });
      }
    }

    if (!_hasMore && !refresh) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      if (currentSource.listKey == '@direct') {
        await _fetchDirectMode(currentSource);
      } else {
        await _fetchApiMode(currentSource, activeParams);
      }
    } catch (e) {
      debugPrint("Load Error: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("加载失败: $e"), duration: const Duration(seconds: 2)),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDirectMode(dynamic currentSource) async {
    int batchSize = 5; 
    List<Wallpaper> newItems = [];
    
    for (int i = 0; i < batchSize; i++) {
      if (!mounted) return;
      final randomId = "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}";
      final separator = currentSource.baseUrl.contains('?') ? '&' : '?';
      final directUrl = "${currentSource.baseUrl}${separator}cache_buster=${_page}_${i}_$randomId";
      double randomRatio = 0.6 + Random().nextDouble(); 

      newItems.add(Wallpaper(
        id: "direct_${_page}_${i}_$randomId",
        thumbUrl: directUrl,
        fullSizeUrl: directUrl,
        resolution: "Random",
        aspectRatio: randomRatio,
        purity: 'sfw', // 直链默认 sfw
        metadata: {},
      ));
    }
    
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _wallpapers.addAll(newItems);
        _page++;
      });
    }
  }

  Future<void> _fetchApiMode(dynamic currentSource, Map<String, dynamic> activeParams) async {
    final Map<String, dynamic> queryParams = Map.from(activeParams);
    queryParams['page'] = _page;
    
    if (currentSource.apiKey.isNotEmpty) {
      queryParams[currentSource.apiKeyParam] = currentSource.apiKey;
    }

    var response = await Dio().get(
      currentSource.baseUrl,
      queryParameters: queryParams,
      options: Options(headers: kAppHeaders), 
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
          
          double ratio = 1.0;
          try {
            var w = item['dimension_x'] ?? item['width'];
            var h = item['dimension_y'] ?? item['height'];
            if (w != null && h != null) {
              ratio = (w as num) / (h as num);
            } else if (item['ratio'] != null) {
              ratio = double.tryParse(item['ratio'].toString()) ?? 1.0;
            }
          } catch (e) {
            ratio = 1.0;
          }
          
          String resolution = "";
          if (item['dimension_x'] != null && item['dimension_y'] != null) {
            resolution = "${item['dimension_x']}x${item['dimension_y']}";
          } else if (item['resolution'] != null) {
            resolution = item['resolution'].toString();
          }

          return Wallpaper(
            id: id,
            thumbUrl: thumb,
            fullSizeUrl: full,
            resolution: resolution,
            views: item['views'] ?? 0,
            favorites: item['favorites'] ?? 0,
            aspectRatio: ratio,
            purity: item['purity'] ?? 'sfw', // 解析分级
            metadata: item is Map<String, dynamic> ? item : {},
          );
        }).where((w) => w.thumbUrl.isNotEmpty).toList();

        if (mounted) {
          setState(() {
            _wallpapers.addAll(newWallpapers);
            _page++; 
          });
        }
      } else {
         if (mounted) setState(() => _hasMore = false);
      }
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
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar(
              pinned: false,
              floating: true,
              title: Text(appState.currentSource.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: "搜索",
                  onPressed: () async {
                    final query = await _showSearchDialog();
                    if (query != null && mounted) {
                      context.read<AppState>().updateSearchQuery(query);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  tooltip: "筛选",
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FilterPage()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: "设置",
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            CupertinoSliverRefreshControl(
              onRefresh: _handleRefresh,
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childCount: _wallpapers.length,
                itemBuilder: (context, index) {
                  return _buildWallpaperItem(_wallpapers[index]);
                },
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: _isLoading 
                      ? const CircularProgressIndicator.adaptive()
                      : (!_hasMore && _wallpapers.isNotEmpty) 
                          ? const Text("--- 我是有底线的 ---", style: TextStyle(color: Colors.grey))
                          : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _wallpapers.length > 20 ? FloatingActionButton.small(
        onPressed: () {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        },
        child: const Icon(Icons.arrow_upward),
      ) : null,
    );
  }

  Future<String?> _showSearchDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: TextField(
            controller: ctrl, 
            autofocus: true, 
            decoration: const InputDecoration(
              hintText: "输入关键字搜索...",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("取消")
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text), 
              child: const Text("搜索")
            )
          ],
        );
      }
    );
  }

  // === 辅助方法：获取分级颜色 ===
  Color _getPurityColor(String purity) {
    switch (purity.toLowerCase()) {
      case 'sketchy':
        return const Color(0xFFE6E649); // 黄色/金色
      case 'nsfw':
        return const Color(0xFFE23838); // 红色
      case 'sfw':
      default:
        return const Color(0xFF42A5F5); // 默认蓝色或官网的绿色，这里用官网SFW类似的绿色或保持主题色
        // Wallhaven 官网 SFW 其实通常没有强烈的边框，或者用绿色。
        // 这里为了明显区分，暂用 Wallhaven 风格绿色：
        // return const Color(0xFF99CC33); 
    }
  }

  // 是否仅 Wallhaven 才显示边框？你提到 "首页图片复刻上图中分级对应的颜色边框...只针对 Wallhaven"。
  // 我们可以通过判断 baseUrl 是否包含 wallhaven 来处理，或者直接根据 purity 值（非 Wallhaven 可能没这个值）
  
  Widget _buildWallpaperItem(Wallpaper wallpaper) {
    final appState = context.read<AppState>();
    final double radius = appState.homeCornerRadius;
    final colorScheme = Theme.of(context).colorScheme;

    // 判断是否是 Wallhaven 源 (简单判断 url)
    final isWallhaven = appState.currentSource.baseUrl.contains('wallhaven');
    
    // 只有 Wallhaven 源且 purity 有效时才显示边框
    Color? borderColor;
    if (isWallhaven) {
      if (wallpaper.purity == 'sketchy') borderColor = const Color(0xFFEEEE11);
      else if (wallpaper.purity == 'nsfw') borderColor = const Color(0xFFFF0033);
      else if (wallpaper.purity == 'sfw') borderColor = const Color(0xFF99CC33);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailPage(wallpaper: wallpaper)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius), 
          color: colorScheme.surfaceContainerHighest,
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ],
          // === 边框逻辑 ===
          border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius), // 减去边框宽度，或者保持一致
          child: AspectRatio(
            aspectRatio: wallpaper.aspectRatio, 
            child: Hero(
              tag: wallpaper.id,
              child: CachedNetworkImage(
                imageUrl: wallpaper.thumbUrl,
                httpHeaders: kAppHeaders,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
