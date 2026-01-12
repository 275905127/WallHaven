import 'dart:ui'; 
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
  bool _hideUI = false;

  @override
  void initState() {
    super.initState();
    _details = Map.from(widget.wallpaper.metadata);
    _fetchExtraDetails();
  }

  Future<void> _fetchExtraDetails() async {
    final appState = context.read<AppState>();
    if (!appState.currentSource.baseUrl.contains('wallhaven')) return;
    if (_details['tags'] != null && _details['uploader'] != null) return;
    if (widget.wallpaper.id.startsWith("direct_")) return;

    setState(() => _isLoadingDetails = true);
    
    try {
      final url = "https://wallhaven.cc/api/v1/w/${widget.wallpaper.id}";
      // 使用动态 Headers
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

  Future<void> _saveImage() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();

      final headers = context.read<AppState>().getHeaders();
      
      var response = await Dio().get(
        widget.wallpaper.fullSizeUrl,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );

      await Gal.putImageBytes(
        Uint8List.fromList(response.data),
        name: "wallpaper_${widget.wallpaper.id}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ 保存成功"), 
            backgroundColor: Colors.white, 
            behavior: SnackBarBehavior.floating,
            contentTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 保存失败: $e"), backgroundColor: Colors.redAccent),
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
    final headers = appState.getHeaders();
    
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
          // === 1. 图片主体 ===
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _hideUI = !_hideUI), 
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.wallpaper.id,
                  child: CachedNetworkImage(
                    imageUrl: widget.wallpaper.fullSizeUrl,
                    httpHeaders: headers, 
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white24)),
                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 50)),
                  ),
                ),
              ),
            ),
          ),

          // === 2. 顶部透明渐变栏 (更柔和) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: _hideUI ? -100 : 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // 圆形磨砂返回键
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withOpacity(0.1),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // === 3. 底部晶莹剔透悬浮岛 (核心修改) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            bottom: _hideUI ? -200 : 32, 
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                // 1. 强力模糊
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), 
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // 2. 关键：用微透的白色，而不是黑色！这样在黑底上才会有玻璃感
                    color: Colors.white.withOpacity(0.08), 
                    // 3. 亮白细边框，勾勒轮廓
                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1), 
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 第一行：信息 + 核心操作
                      Row(
                        children: [
                          // 左侧：参数信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getResolution(), 
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 18,
                                    fontFamily: 'Roboto', 
                                    letterSpacing: 0.5
                                  )
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    // 胶囊样式的标签
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6)
                                      ),
                                      child: Text(
                                        _getFileSize(), 
                                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getUploaderName(), 
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                                      maxLines: 1, overflow: TextOverflow.ellipsis
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // 右侧：收藏 + 下载
                          Row(
                            children: [
                              // 收藏按钮
                              Consumer<AppState>(
                                builder: (ctx, state, _) {
                                  final isFav = state.isFavorite(widget.wallpaper);
                                  return IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border, 
                                      color: isFav ? const Color(0xFFFF3B30) : Colors.white70, 
                                      size: 26
                                    ),
                                    onPressed: () => state.toggleFavorite(widget.wallpaper),
                                  );
                                }
                              ),
                              const SizedBox(width: 12),
                              
                              // 下载按钮：纯白圆形，强烈对比
                              Material(
                                color: Colors.white, 
                                shape: const CircleBorder(),
                                elevation: 4,
                                child: InkWell(
                                  onTap: _saveImage,
                                  customBorder: const CircleBorder(),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: _isDownloading 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : const Icon(Icons.arrow_downward, color: Colors.black, size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // 第二行：相似图片 (仅 Wallhaven)
                      if (appState.currentSource.baseUrl.contains('wallhaven')) ...[
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: _searchSimilar,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              // 更浅的半透明白
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05))
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_search, color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "查找相似图片", 
                                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                        )
                      ]
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

  String _getUploaderName() {
    if (_details['uploader'] != null) {
      return _details['uploader'] is Map ? _details['uploader']['username'] : _details['uploader'].toString();
    }
    return "Unknown";
  }

  String _getResolution() {
    if (widget.wallpaper.resolution.isNotEmpty) return widget.wallpaper.resolution;
    if (_details['dimension_x'] != null) return "${_details['dimension_x']} × ${_details['dimension_y']}";
    return "Details";
  }

  String _getFileSize() {
    if (_details['file_size'] != null) {
      final size = _details['file_size'] as num;
      if (size > 1024 * 1024) {
        return "${(size / 1024 / 1024).toStringAsFixed(1)} MB";
      }
      return "${(size / 1024).toStringAsFixed(0)} KB";
    }
    return "HQ";
  }
}
