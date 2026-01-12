import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart'; 
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers.dart';
import '../models/wallpaper.dart'; // 引入 Wallpaper 模型

class ImageDetailPage extends StatefulWidget {
  final Wallpaper wallpaper; // 接收整个对象

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
    // 初始化时，先使用传递过来的 metadata
    _details = Map.from(widget.wallpaper.metadata);
    _fetchExtraDetails();
  }

  // === 智能获取详情逻辑 ===
  Future<void> _fetchExtraDetails() async {
    // 只有当 ID 看起来像 Wallhaven 的 ID (通常是数字或字母组合) 且没有足够信息时才请求
    // 简单的判断逻辑：如果 metadata 为空或者缺关键字段，尝试请求 Wallhaven API
    // 注意：这里假设如果 baseUrl 包含 'wallhaven'，则尝试获取详情
    // 为了更通用，你可以检查 metadata 是否有 'uploader' 等字段
    
    if (_details['uploader'] != null && _details['tags'] != null) {
      return; // 信息已经很全了
    }

    // 假设 ID 是 wallhaven ID，尝试构建请求
    // 如果不是 wallhaven ID，这个请求会失败，我们捕获它并不做处理即可
    setState(() => _isLoadingDetails = true);
    
    try {
      // 只有 ID 看起来比较短且没有特殊字符时才尝试 (直链 ID 是很长的 random 字符串)
      if (widget.wallpaper.id.startsWith("direct_")) {
        setState(() => _isLoadingDetails = false);
        return;
      }

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
      debugPrint("Detail fetch skipped or failed: $e");
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
        onReceiveProgress: (received, total) {
           // 这里可以加下载进度条
        }
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

  @override
  Widget build(BuildContext context) {
    // 全局背景色
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === 1. 顶部大图 ===
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.5,
            pinned: true,
            backgroundColor: bgColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.wallpaper.id,
                child: GestureDetector(
                  onTap: () {
                     // 点击可以进入全屏预览模式（如果需要的话，这里暂时略过）
                  },
                  child: CachedNetworkImage(
                    imageUrl: widget.wallpaper.fullSizeUrl,
                    httpHeaders: kAppHeaders,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.black26),
                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error)),
                  ),
                ),
              ),
            ),
          ),

          // === 2. 详情内容区域 ===
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 操作栏 (剪裁、下载、分享) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.crop, "剪裁", onPressed: () {}), // 暂未实现
                      _buildActionButton(Icons.download, "下载", onPressed: _saveImage, isLoading: _isDownloading),
                      _buildActionButton(Icons.share, "分享", onPressed: () {}), // 暂未实现
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- 信息列表 ---
                  // 上传者
                  if (_details.containsKey('uploader')) 
                    _buildInfoRow(
                      Icons.person_outline, 
                      "上传者: ${_details['uploader'] is Map ? _details['uploader']['username'] : _details['uploader']}",
                      trailing: const Icon(Icons.bookmark_border, size: 20, color: Colors.grey),
                    ),
                  
                  // 链接 (只展示部分)
                  _buildInfoRow(Icons.link, widget.wallpaper.fullSizeUrl, isLink: true),

                  // 浏览量 & 收藏
                  if (_details.containsKey('views'))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("${_details['views']} 浏览量", style: TextStyle(color: textColor)),
                          const SizedBox(width: 20),
                          const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("${_details['favorites'] ?? widget.wallpaper.favorites} 收藏", style: TextStyle(color: textColor)),
                        ],
                      ),
                    ),

                  // 分辨率
                  if (widget.wallpaper.resolution.isNotEmpty || _details.containsKey('dimension_x'))
                    _buildInfoRow(
                      Icons.aspect_ratio, 
                      widget.wallpaper.resolution.isNotEmpty 
                          ? widget.wallpaper.resolution 
                          : "${_details['dimension_x']}x${_details['dimension_y']}"
                    ),

                  // 文件大小
                  if (_details.containsKey('file_size'))
                    _buildInfoRow(Icons.data_usage, "${(_details['file_size'] / 1024).toStringAsFixed(0)} Kb"),

                  // 创建时间
                  if (_details.containsKey('created_at'))
                    _buildInfoRow(Icons.calendar_today_outlined, _details['created_at'].toString()),

                  // 标签信息
                  if (_details.containsKey('tags')) ...[
                    const SizedBox(height: 16),
                    const Text("标签", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_details['tags'] as List).map((tag) {
                        String tagName = tag is Map ? tag['name'] : tag.toString();
                        return Chip(
                          label: Text(tagName, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }).toList(),
                    ),
                  ],

                  // 类似搜索 (模拟按钮)
                  if (_isLoadingDetails)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    ),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onPressed, bool isLoading = false}) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed, 
          icon: isLoading 
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
              : Icon(icon, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Widget? trailing, bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(
                color: isLink ? Colors.green : Theme.of(context).textTheme.bodyMedium?.color, 
                decoration: isLink ? TextDecoration.underline : null,
                decorationColor: Colors.green,
              ),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
