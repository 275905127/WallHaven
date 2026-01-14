import 'package:flutter/material.dart';
import '../models/wallpaper.dart';

class WallpaperDetailPage extends StatelessWidget {
  final Wallpaper wallpaper;
  const WallpaperDetailPage({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                wallpaper.url,
                fit: BoxFit.contain,
              ),
            ),
          ),
          _infoBar(context),
        ],
      ),
    );
  }

  Widget _infoBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconText(Icons.aspect_ratio, "${wallpaper.width}×${wallpaper.height}"),
          _iconButton(Icons.file_download),
          _iconButton(Icons.wallpaper),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () {},
    );
  }
}
