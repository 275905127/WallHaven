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
          const SnackBar(content: Text("✅ 保存成功"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 保存失败: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
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
          // === 1. 图片层 ===
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

          // === 2. 顶部导航栏 ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            top: _hideUI ? -100 : 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 8, right: 8, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // === 3. 底部悬浮岛 (视觉核心优化) ===
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            bottom: _hideUI ? -200 : 34, 
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32), // 更圆润的圆角
              child: BackdropFilter(
                // 增加模糊度，更有质感
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    // 降低不透明度，更通透
                    color: const Color(0xFF1A1A1A).withOpacity(0.4), 
                    // 极细的边框，若隐若现
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1), 
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 左侧信息
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getResolution(), 
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.w600, 
                                    fontSize: 17,
                                    letterSpacing: 0.5
                                  )
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
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
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // 收藏按钮
                          Consumer<AppState>(
                            builder: (ctx, state, _) {
                              final isFav = state.isFavorite(widget.wallpaper);
                              return IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border, 
                                  color: isFav ? const Color(0xFFFF453A) : Colors.white, // iOS 风格红
                                  size: 28
                                ),
                                onPressed: () => state.toggleFavorite(widget.wallpaper),
                              );
                            }
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // 下载按钮 (高亮设计)
                          Material(
                            color: Colors.white, // 纯白背景
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: _saveImage,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: _isDownloading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                                  : const Icon(Icons.arrow_downward_rounded, color: Colors.black, size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // 如果是 Wallhaven 源，显示相似图片入口
                      if (appState.currentSource.baseUrl.contains('wallhaven')) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _searchSimilar,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16)
                            ),
                            child: const Center(
                              child: Text(
                                "查找相似图片", 
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)
                              ),
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
    return "Wallpaper";
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
