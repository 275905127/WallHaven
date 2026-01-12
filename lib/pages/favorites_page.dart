import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers.dart';
import '../models/wallpaper.dart';
import 'image_detail_page.dart';
import 'home_page.dart'; // 引入 SkeletonPlaceholder

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final favorites = appState.favorites;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appState.locale.languageCode == 'zh' ? "我的收藏" : "Favorites",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    appState.locale.languageCode == 'zh' ? "暂无收藏" : "No Favorites",
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : MasonryGridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final wallpaper = favorites[index];
                return _buildWallpaperItem(context, wallpaper);
              },
            ),
    );
  }

  Widget _buildWallpaperItem(BuildContext context, Wallpaper wallpaper) {
    final appState = context.read<AppState>();
    final double radius = appState.homeCornerRadius;
    final colorScheme = Theme.of(context).colorScheme;

    // 收藏页通常不需要分级边框，保持干净
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailPage(wallpaper: wallpaper)));
      },
      child: Container(
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
              tag: "fav_${wallpaper.id}",
              child: CachedNetworkImage(
                imageUrl: wallpaper.thumbUrl,
                // 修复：使用新的常量名 kDefaultAppHeaders
                httpHeaders: kDefaultAppHeaders,
                fit: BoxFit.cover,
                // 优化：使用骨架屏
                placeholder: (context, url) => const SkeletonPlaceholder(),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
