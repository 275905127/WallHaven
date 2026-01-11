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
  
  // === 🛡️ 新增：防抖动时间锁 (防止滑动过快触发大量请求) ===
  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);

  // === 🎭 定义通用的伪装头 (浏览器 User-Agent) ===
  final Map<String, String> _headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  };

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

    // === 🛡️ 安全检查：如果距离上次请求不足 2 秒，且不是强制刷新，则忽略 ===
    // 这能有效防止因惯性滑动导致的重复触发
    if (!refresh && DateTime.now().difference(_lastFetchTime).inSeconds < 2) {
      return;
    }
    _lastFetchTime = DateTime.now();

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
      // 🛡️ 修改点1：减少单次批量，由 8 改为 5
      int batchSize = 5; 
      
      for (int i = 0; i < batchSize; i++) {
        if (!mounted) return;

        // 生成强力随机参数，防止缓存
        final randomId = "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}";
        final separator = currentSource.baseUrl.contains('?') ? '&' : '?';
        // 拼接 _r 参数放在最后
        final directUrl = "${currentSource.baseUrl}${separator}cache_buster=${_page}_${i}_$randomId";

        double randomRatio = 0.6 + Random().nextDouble(); 

        final newItem = Wallpaper(
          id: "direct_${_page}_${i}_$randomId",
          thumbUrl: directUrl,
          fullSizeUrl: directUrl,
          resolution: "Random",
          views: 0,
          favorites: 0,
          aspectRatio: randomRatio,
        );

        if (mounted) {
          setState(() {
            _wallpapers.add(newItem);
          });
        }
        
        // 🛡️ 修改点2：增加延时，由 600ms 改为 1000ms (1秒)
        // 慢一点，但更安全，不容易被 API 判定为攻击
        await Future.delayed(const Duration(milliseconds: 1000));
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
      final Map<String, dynamic> queryParams = {};
      queryParams.addAll(activeParams);

      queryParams['page'] = _page;
      
      if (currentSource.apiKey.isNotEmpty) {
        queryParams[currentSource.apiKeyParam] = currentSource.apiKey;
      }

      // 给 API 请求也加上 Headers
      var response = await Dio().get(
        currentSource.baseUrl,
        queryParameters: queryParams,
        options: Options(headers: _headers), 
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

            return Wallpaper(
              id: id,
              thumbUrl: thumb,
              fullSizeUrl: full,
              resolution: "",
              views: 0,
              favorites: 0,
              aspectRatio: ratio,
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: wallpaper.aspectRatio,
            child: Hero(
              tag: wallpaper.id,
              child: Image.network(
                wallpaper.thumbUrl,
                fit: BoxFit.cover,
                // === 核心：添加 Headers 伪装成浏览器 ===
                headers: _headers, 
                // ===================================
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.transparent);
                },
                errorBuilder: (_, error, stack) {
                   debugPrint("Img Error: $error");
                   return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
