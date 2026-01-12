import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../models/wallpaper.dart';
import '../providers.dart';
import 'filter_page.dart';
import 'image_detail_page.dart';
import 'settings_page.dart';

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

  // ✅ 防 Nekos.best / 类似源：被 403/429 后短暂熄火，别继续刷去送死
  DateTime? _rateLimitedUntil;
  String? _lastRateLimitToastKey;

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchWallpapers();
    }
  }

  dynamic _getValueByPath(dynamic json, String path) {
    if (path.isEmpty) return json;
    final keys = path.split('.');
    dynamic current = json;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  bool _isNekosBest(String url) => url.contains('nekos.best');

  void _toastOnce(String key, String msg) {
    if (!mounted) return;
    if (_lastRateLimitToastKey == key) return;
    _lastRateLimitToastKey = key;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _fetchWallpapers({bool refresh = false}) async {
    if (_isLoading) return;

    // ✅ 若刚被 403/429，直接别请求了
    if (!refresh && _rateLimitedUntil != null) {
      final now = DateTime.now();
      if (now.isBefore(_rateLimitedUntil!)) {
        final remain = _rateLimitedUntil!.difference(now).inSeconds;
        _toastOnce(
          'rl_${_rateLimitedUntil!.millisecondsSinceEpoch}',
          "被限流了，等 $remain 秒再刷",
        );
        return;
      } else {
        _rateLimitedUntil = null;
      }
    }

    // ✅ 你原来的 1 秒节流保留
    if (!refresh && DateTime.now().difference(_lastFetchTime).inMilliseconds < 900) {
      return;
    }
    _lastFetchTime = DateTime.now();

    final appState = context.read<AppState>();
    final currentSource = appState.currentSource;
    final activeParams = appState.activeParams;

    final currentHash = "${currentSource.baseUrl}|${activeParams.toString()}";

    if (refresh || _lastSourceHash != currentHash) {
      if (mounted) {
        setState(() {
          _page = 1;
          _wallpapers.clear();
          _lastSourceHash = currentHash;
          _hasMore = true;
          _rateLimitedUntil = null;
          _lastRateLimitToastKey = null;
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
          SnackBar(
            content: Text("加载失败: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // === ✅ 直链模式：一次请求拿到最终直链 + 真实比例（你这段我整理成稳定能跑的） ===
  Future<void> _fetchDirectMode(dynamic currentSource) async {
    const int batchSize = 8;
    const int headerBytes = 32768; // 32KB
    const Duration perItemDelay = Duration(milliseconds: 220);
    const Duration batchCooldown = Duration(milliseconds: 900);

    final appState = context.read<AppState>();

    // 1) 拼参数（筛选）
    final paramBuffer = StringBuffer();
    appState.activeParams.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        paramBuffer.write("&$key=$value");
      }
    });
    final paramString = paramBuffer.toString();

    final dio = Dio();

    (int, int)? parseImageSize(Uint8List b) {
      // PNG
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
        final w = readBe32(16);
        final h = readBe32(20);
        if (w > 0 && h > 0) return (w, h);
      }

      // JPEG
      bool isJpg() => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;
      if (isJpg()) {
        int i = 2;
        while (i + 9 < b.length) {
          if (b[i] != 0xFF) {
            i++;
            continue;
          }
          final marker = b[i + 1];
          final isSof =
              (marker >= 0xC0 && marker <= 0xCF) && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
          final len = (b[i + 2] << 8) | b[i + 3];
          if (len < 2) break;

          if (isSof && i + 8 < b.length) {
            final h = (b[i + 5] << 8) | b[i + 6];
            final w = (b[i + 7] << 8) | b[i + 8];
            if (w > 0 && h > 0) return (w, h);
            break;
          }
          i += 2 + len;
        }
      }

      // WEBP (VP8X/VP8L)
      bool isWebp() =>
          b.length > 30 &&
          b[0] == 0x52 &&
          b[1] == 0x49 &&
          b[2] == 0x46 &&
          b[3] == 0x46 &&
          b[8] == 0x57 &&
          b[9] == 0x45 &&
          b[10] == 0x42 &&
          b[11] == 0x50;
      if (isWebp()) {
        for (int i = 12; i + 18 < b.length; i++) {
          // VP8X
          if (b[i] == 0x56 && b[i + 1] == 0x50 && b[i + 2] == 0x38 && b[i + 3] == 0x58) {
            final wMinus1 = b[i + 12] | (b[i + 13] << 8) | (b[i + 14] << 16);
            final hMinus1 = b[i + 15] | (b[i + 16] << 8) | (b[i + 17] << 16);
            final w = wMinus1 + 1;
            final h = hMinus1 + 1;
            if (w > 0 && h > 0) return (w, h);
          }
          // VP8L
          if (b[i] == 0x56 && b[i + 1] == 0x50 && b[i + 2] == 0x38 && b[i + 3] == 0x4C) {
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
            "Range": "bytes=0-${headerBytes - 1}",
          },
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ),
      );

      final finalUrl = resp.realUri.toString();
      final ct = resp.headers.value('content-type') ?? '';

      if (ct.startsWith('image/')) {
        final bytes = Uint8List.fromList(resp.data as List<int>);
        final sz = parseImageSize(bytes);
        if (sz != null) {
          final r = sz.$1 / sz.$2;
          final ratio = r.isFinite ? r.clamp(0.35, 2.2) : 1.0;
          return (finalUrl, ratio.toDouble());
        }
        return (finalUrl, 1.0);
      }

      // JSON：抽 url 再 Range 一次
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
      } catch (_) {}

      return (finalUrl, 1.0);
    }

    final List<Wallpaper> newItems = [];

    for (int i = 0; i < batchSize; i++) {
      if (!mounted) return;

      final randomId =
          "${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}";
      final separator = currentSource.baseUrl.contains('?') ? '&' : '?';

      final requestUrl =
          "${currentSource.baseUrl}${separator}cache_buster=${_page}_${i}_$randomId$paramString";

      final resolved = await resolveFinalUrlAndRatio(requestUrl);
      final finalUrl = resolved.$1;
      final ratio = resolved.$2;

      newItems.add(
        Wallpaper(
          id: "direct_${finalUrl.hashCode}",
          thumbUrl: finalUrl,
          fullSizeUrl: finalUrl,
          resolution: "Random",
          aspectRatio: ratio,
          purity: 'sfw',
          metadata: {"source_request_url": requestUrl},
        ),
      );

      await Future.delayed(perItemDelay);
    }

    if (mounted) {
      setState(() {
        _wallpapers.addAll(newItems);
        _page++;
      });
    }

    await Future.delayed(batchCooldown);
  }

  // === ✅ API 模式：重点修 Nekos.best 403 不再“直接抛异常 + 白屏” ===
  Future<void> _fetchApiMode(dynamic currentSource, Map<String, dynamic> activeParams) async {
    final Map<String, dynamic> queryParams = Map.from(activeParams);
    queryParams['page'] = _page;

    if (currentSource.apiKey.isNotEmpty) {
      queryParams[currentSource.apiKeyParam] = currentSource.apiKey;
    }

    final bool isNekos = _isNekosBest(currentSource.baseUrl);

    final dio = Dio();

    // Nekos.best：给它一个更像“正常 API 客户端”的头（别用你那种图片 Accept 去打 JSON）
    final headers = <String, String>{
      ...kAppHeaders,
      if (isNekos) "Accept": "application/json",
      if (isNekos) "Referer": "https://nekos.best/",
      if (isNekos) "Origin": "https://nekos.best",
    };

    final response = await dio.get(
      currentSource.baseUrl,
      queryParameters: queryParams,
      options: Options(
        headers: headers,
        // ✅ 关键：403/429 不抛异常，交给我们自己处理
        validateStatus: (code) => code != null && code >= 200 && code < 500,
      ),
    );

    final code = response.statusCode ?? 0;

    // ✅ Nekos.best：403/429 -> 熄火一会儿，别继续刷
    if (isNekos && (code == 403 || code == 429)) {
      // 403：可能是 WAF/风控；429：明确限流
      final seconds = code == 429 ? 30 : 45;
      _rateLimitedUntil = DateTime.now().add(Duration(seconds: seconds));
      _toastOnce("nekos_$code", "Nekos.best 把你挡了($code)，先歇 $seconds 秒");
      if (mounted) setState(() => _hasMore = false);
      return;
    }

    if (code != 200) {
      // 其他非 200：别白屏，至少让 UI 继续跑
      debugPrint("API status=$code");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("接口返回 $code"), duration: const Duration(seconds: 2)),
        );
      }
      // 这里不直接 _hasMore=false（除非你想一错就停）
      return;
    }

    var rawData = _getValueByPath(response.data, currentSource.listKey);

    List listData = [];
    if (rawData is List) {
      listData = rawData;
    } else if (rawData is Map) {
      listData = [rawData];
    }

    if (listData.isEmpty) {
      if (mounted) setState(() => _hasMore = false);
      return;
    }

    final newWallpapers = listData.map((item) {
      final thumb = _getValueByPath(item, currentSource.thumbKey) ?? "";
      final full = _getValueByPath(item, currentSource.fullKey) ?? thumb;
      final id = _getValueByPath(item, currentSource.idKey)?.toString() ??
          full.hashCode.toString();

      double ratio = 1.0;
      try {
        final w = item['dimension_x'] ?? item['width'];
        final h = item['dimension_y'] ?? item['height'];
        if (w != null && h != null) {
          ratio = (w as num) / (h as num);
        } else if (item['ratio'] != null) {
          ratio = double.tryParse(item['ratio'].toString()) ?? 1.0;
        }
      } catch (_) {
        ratio = 1.0;
      }

      String resolution = "";
      if (item['dimension_x'] != null && item['dimension_y'] != null) {
        resolution = "${item['dimension_x']}x${item['dimension_y']}";
      } else if (item['resolution'] != null) {
        resolution = item['resolution'].toString();
      }

      final safeRatio = ratio.isFinite ? ratio.clamp(0.35, 2.2).toDouble() : 1.0;

      return Wallpaper(
        id: id,
        thumbUrl: thumb,
        fullSizeUrl: full,
        resolution: resolution,
        views: item['views'] ?? 0,
        favorites: item['favorites'] ?? 0,
        aspectRatio: safeRatio,
        purity: item['purity'] ?? 'sfw',
        metadata: item is Map<String, dynamic> ? item : {},
      );
    }).where((w) => w.thumbUrl.isNotEmpty).toList();

    if (mounted) {
      setState(() {
        _wallpapers.addAll(newWallpapers);
        _page++;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchWallpapers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (_lastSourceHash != null &&
        _lastSourceHash !=
            "${appState.currentSource.baseUrl}|${appState.activeParams.toString()}") {
      Future.microtask(() => _fetchWallpapers(refresh: true));
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FilterPage()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: "设置",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
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
                          ? const Text("--- 我是有底线的 ---",
                              style: TextStyle(color: Colors.grey))
                          : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _wallpapers.length > 20
          ? FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text("搜索")),
          ],
        );
      },
    );
  }

  Widget _buildWallpaperItem(Wallpaper wallpaper) {
    final appState = context.read<AppState>();
    final double radius = appState.homeCornerRadius;
    final colorScheme = Theme.of(context).colorScheme;

    final isWallhaven = appState.currentSource.baseUrl.contains('wallhaven');

    Color? borderColor;
    if (isWallhaven) {
      if (wallpaper.purity == 'sketchy') {
        borderColor = const Color(0xFFE6E649);
      } else if (wallpaper.purity == 'nsfw') {
        borderColor = const Color(0xFFFF3333);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ImageDetailPage(wallpaper: wallpaper)),
        );
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
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
          if (borderColor != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignInside,
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