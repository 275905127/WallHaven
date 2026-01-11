import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageDetailPage extends StatefulWidget {
  final String imageUrl;
  final String heroTag; // 用于转场动画

  const ImageDetailPage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<ImageDetailPage> createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  bool _isFavorited = false;
  bool _isDownloading = false;

  // 保存图片逻辑
  Future<void> _saveImage() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // 1. 请求权限 (安卓 10+ 其实不需要，但为了保险)
      var status = await Permission.storage.request();
      if (!status.isGranted && !await Permission.photos.isGranted) {
        // 部分机型可能需要这个权限，如果拒绝了提示用户
        // 注意：Android 13+ 使用 photos 权限，老版本用 storage
        // 这里简单处理，如果不是永久拒绝就尝试保存
      }

      // 2. 下载图片数据
      var response = await Dio().get(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // 3. 保存到相册
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: "wallhaven_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("图片已保存到相册！"), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception("保存失败");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("保存失败: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 看图通常用黑色背景
      extendBodyBehindAppBar: true, // 让图片顶到状态栏
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 大图展示
          InteractiveViewer( // 支持双指缩放
            child: Hero(
              tag: widget.heroTag,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. 底部操作栏
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), // 半透明白色
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // 收藏按钮
                  IconButton(
                    icon: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited ? Colors.red : Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorited = !_isFavorited;
                      });
                      // 这里以后可以接收藏 API
                    },
                  ),
                  
                  // 分隔线
                  Container(width: 1, height: 24, color: Colors.grey[300]),

                  // 下载按钮
                  _isDownloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : IconButton(
                          icon: const Icon(Icons.download, color: Colors.black, size: 28),
                          onPressed: _saveImage,
                        ),

                  // 分隔线
                  Container(width: 1, height: 24, color: Colors.grey[300]),

                  // 分享/更多按钮
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black, size: 28),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("分享功能开发中...")));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
