import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

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

  // === 🚀 直链模式：一次请求拿到最终直链 + 真实比例（降低频率防封） ===
  Future<void> _fetchDirectMode(dynamic currentSource) async {
  const int batchSize = 8; // 👈 你说会封：别贪，先稳住
  const int headerBytes = 32768; // 32KB：够解析 jpg/png/webp 头部
  const Duration perItemDelay = Duration(milliseconds: 220); // 👈 降频，防封

  final appState = context.read<AppState>();

  // 1) 构建参数字符串
  final StringBuffer paramBuffer = StringBuffer();
  appState.activeParams.forEach((key, value) {
    if (value != null && value.toString().isNotEmpty) {
      paramBuffer.write("&$key=$value");
    }
  });
  final String paramString = paramBuffer.toString();

  final dio = Dio();

  // 解析宽高：返回 (w,h) 或 null
  (int, int)? parseImageSize(Uint8List b) {
    // --- PNG ---
    bool isPng() =>
        b.length > 24 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47 &&
        b[4] == 0x0D &&
        b[5] == 0x0A &&
        b[6] == 0x1A &&
        b[7] == 0x0A;

    int readBe32(int o) =>
        (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

    if (isPng()) {
      // IHDR width/height 在 offset 16..23
      final w = readBe32(16);
      final h = readBe32(20);
      if (w > 0 && h > 0) return (w, h);
    }

    // --- JPEG ---
    bool isJpg() => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;
    if (isJpg()) {
      int i = 2;
      while (i + 9 < b.length) {
        if (b[i] != 0xFF) {
          i++;
          continue;
        }
        int marker = b[i + 1];
        // SOF0/1/2/3/5/6/7/9/10/11/13/14/15
        bool isSof = (marker >= 0xC0 && marker <= 0xCF) && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
        int len = (b[i + 2] << 8) | b[i + 3];
        if (len < 2) break;

        if (isSof && i + 7 < b.length) {
          final h = (b[i + 5] << 8) | b[i + 6];
          final w = (b[i + 7] << 8) | b[i + 8];
          if (w > 0 && h > 0) return (w, h);
          break;
        }
        i += 2 + len;
      }
    }

    // --- WEBP (只处理 VP8X / VP8L，够覆盖大部分) ---
    bool isWebp() =>
        b.length > 30 &&
        b[0] == 0x52 &&
        b[1] == 0x49 &&
        b[2] == 0x46 &&
        b[3] == 0x46 && // RIFF
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50; // WEBP
    if (isWebp()) {
      // 找 VP8X chunk
      for (int i = 12; i + 16 < b.length; i++) {
        if (b[i] == 0x56 && b[i + 1] == 0x50 && b[i + 2] == 0x38 && b[i + 3] == 0x58) {
          // VP8X: width-1 at i+12..i+14 (3 bytes LE), height-1 at i+15..i+17
          if (i + 18 < b.length) {
            int wMinus1 = b[i + 12] | (b[i + 13] << 8) | (b[i + 14] << 16);
            int hMinus1 = b[i + 15] | (b[i + 16] << 8) | (b[i + 17] << 16);
            final w = wMinus1 + 1;
            final h = hMinus1 + 1;
            if (w > 0 && h > 0) return (w, h);
          }
        }
        // 找 VP8L chunk
        if (b[i] == 0x56 && b[i + 1] == 0x50 && b[i + 2] == 0x38 && b[i + 3] == 0x4C) {
          // VP8L: signature 0x2f at chunk payload start (i+8)
          final p = i + 8;
          if (p + 5 < b.length && b[p] == 0x2F) {
            final b1 = b[p + 1];
            final b2 = b[p + 2];
            final b3 = b[p + 3];
            final b4 = b[p + 4];
            final w = 1 + ((b1 | (b2 << 8)) & 0x3FFF);
            final h = 1 + (((b2 >> 6) | (b3 << 2) | (b4 << 10)) & 0x3FFF);
            if (w > 0 && h > 0) return (w, h);
          }
        }
      }
    }

    return null;
  }

  Future<(String finalUrl, double ratio)> resolveFinalUrlAndRatio(String requestUrl) async {
    final resp = await dio.get(
      requestUrl,
      options: Options(
        headers: {
          ...kAppHeaders,
          // 只取头部，减轻压力 + 更快得到宽高
          "Range": "bytes=0-${headerBytes - 1}",
        },
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (code) => code != null && code >= 200 && code < 400,
      ),
    );

    // 1) 最终直链（关键：固定住，后面不会再抽奖）
    final finalUrl = resp.realUri.toString();

    // 2) 如果直接是图片 bytes：从头部解析宽高
    final ct = resp.headers.value('content-type') ?? '';
    if (ct.startsWith('image/')) {
      final bytes = Uint8List.fromList(resp.data as List<int>);
      final sz = parseImageSize(bytes);
      if (sz != null) {
        final r = sz.$1 / sz.$2;
        // 防极端值（避免 Masonry 被奇怪比例搞炸）
        final ratio = r.isFinite ? r.clamp(0.35, 2.2) : 1.0;
        return (finalUrl, ratio.toDouble());
      }
      return (finalUrl, 1.0);
    }

    // 3) 如果是 JSON：尝试提取 url，再用 Range 抓头部算比例（再来一次，但只在 JSON 情况）
    try {
      final text = utf8.decode(resp.data as List<int>);
      final dynamic j = jsonDecode(text);

      String? extracted;
      if (j is Map) {
        extracted ??= j['url']?.toString();
        extracted ??= j['image']?.toString();
        if (j['data'] is Map) {
          extracted ??= j['data']['url']?.toString();
          extracted ??= j['data']['image']?.toString();
          extracted ??= j['data']['path']?.toString();
        }
      }

      if (extracted != null && extracted.startsWith('http')) {
        final resp2 = await dio.get(
          extracted,
          options: Options(
            headers: {
              ...kAppHeaders,
              "Range": "bytes=0-${headerBytes - 1}",
            },
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (code) => code != null && code >= 200 && code < 400,
          ),
        );

        final final2 = resp2.realUri.toString();
        final bytes2 = Uint8List.fromList(resp2.data as List<int>);
        final sz2 = parseImageSize(bytes2);
        if (sz2 != null) {
          final r = sz2.$1 / sz2.$2;
          final ratio = r.isFinite ? r.clamp(0.35, 2.2) : 1.0;
          return (final2, ratio.toDouble());
        }
        return (final2, 1.0);
      }
    } catch (_) {
      // ignore
    }

    // 兜底：至少固定最终 URL
    return (finalUrl, 1.0);
  }

  final List<Wallpaper> newItems = [];

  for (int i = 0; i < batchSize; i++) {
    if (!mounted) return;

    final randomId = "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}";
    final separator = currentSource.baseUrl.contains('?') ? '&' : '?';

    // 抽奖机 URL（只用一次）
    final requestUrl =
        "${currentSource.baseUrl}${separator}cache_buster=${_page}_${i}_$randomId$paramString";

    // ✅ 一次请求（Range）拿到最终直链 + 真实比例
    final resolved = await resolveFinalUrlAndRatio(requestUrl);
    final finalUrl = resolved.$1;
    final ratio = resolved.$2;

    newItems.add(Wallpaper(
      id: "direct_${finalUrl.hashCode}",
      thumbUrl: finalUrl,
      fullSizeUrl: finalUrl,
      resolution: "Random",
      aspectRatio: ratio,
      purity: 'sfw',
      metadata: {"source_request_url": requestUrl},
    ));

    // 👇 降频防封
    await Future.delayed(perItemDelay);
  }

  if (mounted) {
    setState(() {
      _wallpapers.addAll(newItems);
      _page++;
    });
  }
}
  // ✅ 整批冷却：防止滚动触发下一轮太快（防封关键）
  await Future.delayed(const Duration(milliseconds: 900));

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
