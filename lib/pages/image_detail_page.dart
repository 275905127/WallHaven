Import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart'; 
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers.dart';
import '../models/wallpaper.dart';
import 'home_page.dart'; // 用于跳转相似搜索

class ImageDetailPage extends StatefulWidget {
  final Wallpaper wallpaper;

  const ImageDetailPage({
    super.key,
    required this.wallpaper,
  });

  @override
  State<ImageDetailPage> createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  bool _isDownloading = false;
  Map<String, dynamic> _details = {};
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    // 初始化时先装载现有数据
    _details = Map.from(widget.wallpaper.metadata);
    _fetchExtraDetails();
  }

  // === 获取 Wallhaven 详细信息 ===
  Future<void> _fetchExtraDetails() async {
    final appState = context.read<AppState>();
    // 非 Wallhaven 图源暂不获取详情（除非后续适配其他源）
    if (!appState.currentSource.baseUrl.contains('wallhaven')) return;

    // 如果已有标签信息，说明可能是从详情页进来的或者数据已全，不再请求
    if (_details['tags'] != null && _details['uploader'] != null) return;

    // 直链图片没有 ID，跳过
    if (widget.wallpaper.id.startsWith("direct_")) return;

    setState(() => _isLoadingDetails = true);
    
    try {
      final url = "https://wallhaven.cc/api/v1/w/${widget.wallpaper.id}";
      final response = await Dio().get(url, options: Options(headers: kAppHeaders));
      
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

      var response = await Dio().get(
        widget.wallpaper.fullSizeUrl,
        options: Options(responseType: ResponseType.bytes, headers: kAppHeaders),
      );

      await Gal.putImageBytes(
        Uint8List.fromList(response.data),
        name: "wallhaven_${widget.wallpaper.id}",
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

  // === 跳转相似搜索 ===
  void _searchSimilar() {
    final appState = context.read<AppState>();
    // 设置搜索关键词为 like:id (Wallhaven 专用相似图搜索语法)
    appState.updateSearchQuery("like:${widget.wallpaper.id}");
    
    // 返回首页 (因为首页监听了 query 变化会自动刷新)
    // 或者 push 一个新的 HomePage 实例
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isFav = appState.isFavorite(widget.wallpaper);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    // 计算图片高度，保证能铺满一定比例，同时允许滑动
    // 这里不做固定限制，由 InteractiveViewer 和 AspectRatio 控制
    
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === 1. 顶部图片区域 (支持缩放 & 滑动) ===
          SliverToBoxAdapter(
            child: Stack(
              children: [
                InteractiveViewer(
                  panEnabled: true, // 允许平移
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.wallpaper.id,
                    child: CachedNetworkImage(
                      imageUrl: widget.wallpaper.fullSizeUrl,
                      httpHeaders: kAppHeaders,
                      fit: BoxFit.contain, // 保证完整显示，高度自适应
                      placeholder: (_, __) => AspectRatio(
                        aspectRatio: widget.wallpaper.aspectRatio,
                        child: Container(color: Colors.black12),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox(
                        height: 300,
                        child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                // 返回按钮
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === 2. 详情信息区域 ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 操作栏图标 ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 剪裁 (暂未实现具体逻辑，仅 UI)
                      IconButton(icon: const Icon(Icons.content_cut, size: 28), onPressed: () {}),
                      // 分享 (暂未实现)
                      IconButton(icon: const Icon(Icons.share, size: 28), onPressed: () {}),
                      // 下载
                      IconButton(
                        icon: _isDownloading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download, size: 28),
                        onPressed: _saveImage
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- 核心信息区 (带右侧大书签) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 上传者
                            _buildInfoRow(
                              Icons.person_outline, 
                              "上传者: ${_getUploaderName()}",
                              color: const Color(0xFFC62828), // 红色系图标
                            ),
                            
                            // 链接
                            InkWell(
                              onTap: () => Clipboard.setData(ClipboardData(text: widget.wallpaper.fullSizeUrl)),
                              child: _buildInfoRow(
                                Icons.link, 
                                widget.wallpaper.fullSizeUrl, 
                                isLink: true,
                              ),
                            ),

                            // 浏览量
                            _buildInfoRow(Icons.remove_red_eye_outlined, "${_details['views'] ?? widget.wallpaper.views} 浏览量"),
                            
                            // 收藏量
                            _buildInfoRow(Icons.favorite, "${_details['favorites'] ?? widget.wallpaper.favorites} 收藏量"),

                            // 分辨率
                            _buildInfoRow(Icons.aspect_ratio, _getResolution()),

                            // 大小
                            _buildInfoRow(Icons.info_outline, _getFileSize()),

                            // 时间
                            if (_details['created_at'] != null)
                              _buildInfoRow(Icons.calendar_today, _details['created_at'].toString()),

                            // ❓ 综合信息 (分级, 分类, 格式)
                            _buildInfoRow(
                              Icons.help_outline, 
                              _getMetaString(),
                              color: Colors.green, // 绿色问号
                            ),
                          ],
                        ),
                      ),
                      // 右侧大书签
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.bookmark : Icons.bookmark_border,
                          size: 48,
                          color: isFav ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                        onPressed: () => appState.toggleFavorite(widget.wallpaper),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // 相似搜索链接
                  if (appState.currentSource.baseUrl.contains('wallhaven'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: _searchSimilar,
                        child: Row(
                          children: [
                            Text("相似搜索", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(width: 10),
                            const Text("点击查看相似的图片", style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),

                  // 标签云
                  if (_details['tags'] != null) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_details['tags'] as List).map((tag) {
                        String tagName = tag is Map ? tag['name'] : tag.toString();
                        return Chip(
                          label: Text(tagName, style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shape: StadiumBorder(side: BorderSide(color: Colors.grey.withOpacity(0.5))),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 数据获取辅助 ===
  String _getUploaderName() {
    if (_details['uploader'] != null) {
      return _details['uploader'] is Map ? _details['uploader']['username'] : _details['uploader'].toString();
    }
    return "Unknown";
  }

  String _getResolution() {
    if (widget.wallpaper.resolution.isNotEmpty) return widget.wallpaper.resolution;
    if (_details['dimension_x'] != null) return "${_details['dimension_x']}x${_details['dimension_y']}";
    return "Unknown";
  }

  String _getFileSize() {
    if (_details['file_size'] != null) {
      final size = _details['file_size'] as num;
      return "${(size / 1024).toStringAsFixed(0)} Kb";
    }
    return "Unknown";
  }

  // 拼接：分级, 分类, 格式
  String _getMetaString() {
    String purity = widget.wallpaper.purity.isNotEmpty ? widget.wallpaper.purity : (_details['purity'] ?? "sfw");
    String category = _details['category'] ?? "general";
    String fileType = _details['file_type'] ?? "image/jpeg"; // 默认 jpeg
    
    return "$purity, $category, $fileType";
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false, Color? color}) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? textColor?.withOpacity(0.7)), // 默认微透
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(
                color: isLink ? Colors.green : textColor,
                decoration: isLink ? TextDecoration.underline : null,
                decorationColor: Colors.green,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}