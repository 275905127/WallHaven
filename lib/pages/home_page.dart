Import 'dart:math';
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

  // === 🚀 升级版直链模式：支持筛选参数 ===
  Future<void> _fetchDirectMode(dynamic currentSource) async {
    int batchSize = 5; 
    List<Wallpaper> newItems = [];
    final appState = context.read<AppState>();
    
    // 1. 构建参数字符串 (把筛选条件拼接到 URL 里)
    StringBuffer paramBuffer = StringBuffer();
    appState.activeParams.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        paramBuffer.write("&$key=$value");
      }
    });
    String paramString = paramBuffer.toString();
    
    for (int i = 0; i < batchSize; i++) {
      if (!mounted) return;
      final randomId = "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}";
      final separator = currentSource.baseUrl.contains('?') ? '&' : '?';
      
      // 2. 拼接完整 URL: BaseURL + 随机数 + 筛选参数
      final directUrl = "${currentSource.baseUrl}${separator}cache_buster=${_page}_${i}_$randomId$paramString";
      
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

  // === 核心优化：参考图风格 (无边框 SFW + Stack 布局) ===
  Widget _buildWallpaperItem(Wallpaper wallpaper) {
    final appState = context.read<AppState>();
    final double radius = appState.homeCornerRadius;
    final colorScheme = Theme.of(context).colorScheme;

    // 1. 判断是否是 Wallhaven 源
    final isWallhaven = appState.currentSource.baseUrl.contains('wallhaven');
    
    // 2. 边框逻辑优化：SFW 无边框，Sketchy/NSFW 有边框
    Color? borderColor;
    if (isWallhaven) {
      if (wallpaper.purity == 'sketchy') {
        borderColor = const Color(0xFFE6E649); // 黄色
      } else if (wallpaper.purity == 'nsfw') {
        borderColor = const Color(0xFFFF3333); // 红色
      }
      // SFW 保持 null -> 无边框，视觉减负
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailPage(wallpaper: wallpaper)));
      },
      // 使用 Stack 将边框“浮”在图片上方，解决圆角缝隙问题
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // 底层：图片主体
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius), 
              color: colorScheme.surfaceContainerHighest,
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
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

          // 顶层：边框叠加层 (仅当有颜色时显示)
          if (borderColor != null)
            Positioned.fill(
              child: IgnorePointer( // 确保点击穿透
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: borderColor, 
                      width: 1.5, // 细边框，精致
                      strokeAlign: BorderSide.strokeAlignInside, // 向内对齐，无溢出
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