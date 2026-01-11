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
  
  // 防抖动时间锁
  DateTime _lastFetchTime = DateTime.fromMillisecondsSinceEpoch(0);

  // === 🛡️ 更新：更现代的 User-Agent，尝试绕过 VPN 拦截 ===
  final Map<String, String> _headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
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
      int batchSize = 5; 
      
      for (int i = 0; i < batchSize; i++) {
        if (!mounted) return;

        final randomId = "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}";
        final separator = currentSource.baseUrl.contains('?') ? '&' : '?';
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
                            actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, ctrl.text), 
                                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                                    child: const Text("Go")
                                )
                            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 6),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
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
    final double radius = context.read<AppState>().homeCornerRadius;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ImageDetailPage(imageUrl: wallpaper.fullSizeUrl, heroTag: wallpaper.id)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius), 
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius), 
          child: AspectRatio(
            aspectRatio: wallpaper.aspectRatio,
            child: Hero(
              tag: wallpaper.id,
              child: Image.network(
                wallpaper.thumbUrl,
                fit: BoxFit.cover,
                headers: _headers, 
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
