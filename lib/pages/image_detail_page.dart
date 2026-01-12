import 'dart:ui'; // 用于毛玻璃效果
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart'; 
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers.dart';
import '../models/wallpaper.dart';
import 'home_page.dart'; 

class ImageDetailPage extends StatefulWidget {
  final Wallpaper wallpaper;

  const ImageDetailPage({
    super.key,
    required this.wallpaper,
  });

  @override
  State<ImageDetailPage> createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> with SingleTickerProviderStateMixin {
  bool _isDownloading = false;
  Map<String, dynamic> _details = {};
  bool _isLoadingDetails = false;
  
  // 沉浸式控制：是否隐藏 UI
  bool _hideUI = false;

  @override
  void initState() {
    super.initState();
    _details = Map.from(widget.wallpaper.metadata);
    _fetchExtraDetails();
  }

  // === 获取详情 (Headers 修复版) ===
  Future<void> _fetchExtraDetails() async {
    final appState = context.read<AppState>();
    if (!appState.currentSource.baseUrl.contains('wallhaven')) return;
    if (_details['tags'] != null && _details['uploader'] != null) return;
    if (widget.wallpaper.id.startsWith("direct_")) return;

    setState(() => _isLoadingDetails = true);
    
    try {
      final url = "https://wallhaven.cc/api/v1/w/${widget.wallpaper.id}";
      // ✨ 修复：使用动态 Headers
      final headers = appState.getHeaders();
      final response = await Dio().get(url, options: Options(headers: headers));
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        if (mounted) {
          setState(() {
            _details.addAll(response.data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint("Detail fetch failed: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  // === 下载图片 (Headers 修复版) ===
  Future<void> _saveImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();

      // ✨ 修复：使用动态 Headers (解决 403 下载失败)
      final headers = context.read<AppState>().getHeaders();
      
      var response = await Dio().get(
        widget.wallpaper.fullSizeUrl,
        options: Options(responseType: ResponseType.bytes, headers: headers),
        onReceiveProgress: (count, total) {
          // 这里可以加下载进度条
        },
      );

      await Gal.putImageBytes(
        Uint8List.fromList(response.data),
        name: "wallpaper_${widget.wallpaper.id}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 保存成功"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 保存失败: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _searchSimilar() {
    final appState = context.read<AppState>();
    appState.updateSearchQuery("like:${widget.wallpaper.id}");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    // ✨ 修复：图片加载也需要 Headers
    final headers = appState.getHeaders();
    
    return Scaffold(
      backgroundColor: Colors.black, // 沉浸式背景
      body: Stack(
        children: [
          // === 1. 图片层 (全屏 + 缩放) ===
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _hideUI = !_hideUI), // 点击切换 UI 显示
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.wallpaper.id,
                  child: CachedNetworkImage(
                    imageUrl: widget.wallpaper.fullSizeUrl,
                    httpHeaders: headers, // 注入 Headers
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
                  ),
                ),
              ),
            ),
          ),

          // === 2. 顶部导航栏 (渐变阴影) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _hideUI ? -100 : 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 10, right: 10, bottom: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // 顶部操作按钮 (如果有)
                ],
              ),
            ),
          ),

          // === 3. 底部毛玻璃信息栏 (核心视觉升级) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _hideUI ? -300 : 20, // 隐藏时移出屏幕
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 高斯模糊
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), // 半透明黑底
                    border: Border.all(color: Colors.white.withOpacity(0.1)), // 极细边框增加质感
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：标题/链接 + 收藏 + 下载
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getResolution(), 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getFileSize(), 
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)
                                ),
                              ],
                            ),
                          ),
                          // 收藏按钮
                          Consumer<AppState>(
                            builder: (ctx, state, _) {
                              final isFav = state.isFavorite(widget.wallpaper);
                              return IconButton(
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white),
                                onPressed: () => state.toggleFavorite(widget.wallpaper),
                              );
                            }
                          ),
                          const SizedBox(width: 8),
                          // 下载按钮 (带背景)
                          Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                              icon: _isDownloading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.download, color: Colors.black),
                              onPressed: _saveImage,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),

                      // 第二行：详细信息 (标签/上传者)
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Text(_getUploaderName(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const Spacer(),
                          if (appState.currentSource.baseUrl.contains('wallhaven'))
                            GestureDetector(
                              onTap: _searchSimilar,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                child: const Row(
                                  children: [
                                    Text("相似图", style: TextStyle(color: Colors.white, fontSize: 12)),
                                    Icon(Icons.chevron_right, color: Colors.white, size: 14)
                                  ],
                                ),
                              ),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 辅助方法 ===
  String _getUploaderName() {
    if (_details['uploader'] != null) {
      return _details['uploader'] is Map ? _details['uploader']['username'] : _details['uploader'].toString();
    }
    return "Unknown User";
  }

  String _getResolution() {
    if (widget.wallpaper.resolution.isNotEmpty) return widget.wallpaper.resolution;
    if (_details['dimension_x'] != null) return "${_details['dimension_x']}x${_details['dimension_y']}";
    return "壁纸详情";
  }

  String _getFileSize() {
    if (_details['file_size'] != null) {
      final size = _details['file_size'] as num;
      return "${(size / 1024 / 1024).toStringAsFixed(2)} MB";
    }
    return "High Quality";
  }
}
