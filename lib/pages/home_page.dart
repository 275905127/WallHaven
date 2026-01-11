import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // 引入随机数库

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

    // === 核心修改：安全版直链模式 (防止被封) ===
    if (currentSource.listKey == '@direct') {
      // 这里的数量不要太大，建议 6-8 张，贪多容易被封
      int batchSize = 8; 

      for (int i = 0; i < batchSize; i++) {
        // 如果页面已经关了，停止加载
        if (!mounted) return;

        final randomId = Random().nextInt(1000000);
        final separator = currentSource.baseUrl.contains('?') ? '&' : '?';
        // 拼接随机参数
        final directUrl = "${currentSource.baseUrl}${separator}_r=${_page}_$index$randomId";

        final newItem = Wallpaper(
          id: "direct_${_page}_${i}_$randomId",
          thumbUrl: directUrl,
          fullSizeUrl: directUrl,
          resolution: "Random",
          views: 0,
          favorites: 0,
        );

        if (mounted) {
          setState(() {
            _wallpapers.add(newItem);
          });
        }

        // === 关键保命措施 ===
        // 每加载一张，休息 600 毫秒。
        // 这样 1 秒钟最多请求 1-2 次，大大降低被封风险。
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (mounted) {
        setState(() {
          _page++;
          _isLoading = false;
        });
      }
      return; 
    }
    // ============================================

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

            return Wallpaper(
              id: id,
              thumbUrl: thumb,
              fullSizeUrl: full,
              resolution: "",
              views: 0,
              favorites: 0,
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
