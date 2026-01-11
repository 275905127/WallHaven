import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart'; // 【改动点1】引用新库
import 'package:permission_handler/permission_handler.dart';

class ImageDetailPage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

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

  Future<void> _saveImage() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // 1. 权限检查 (GAL 库会自动处理大部分权限，但为了保险保留这个)
      // Android 10+ 不需要写权限也能保存，Android 9 以下需要
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      // 2. 下载图片数据
      var response = await Dio().get(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // 3. 【改动点2】使用 Gal 保存图片到相册
      // Gal.putImageBytes 直接把二进制数据存为图片，非常方便
      await Gal.putImageBytes(
        Uint8List.fromList(response.data),
        name: "wallhaven_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ 图片已保存到相册！"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        // 如果是用户拒绝权限，Gal 会抛出 GalExceptionType.accessDenied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 保存失败: $e"), backgroundColor: Colors.red),
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
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
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
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
                    },
                  ),
                  Container(width: 1, height: 24, color: Colors.grey[300]),
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
                  Container(width: 1, height: 24, color: Colors.grey[300]),
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
