import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../models/wallpaper.dart';
import '../providers.dart';
import 'image_detail_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final favorites = appState.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.locale.languageCode == 'zh' ? "我的收藏" : "My Favorites"),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    appState.locale.languageCode == 'zh' ? "暂无收藏" : "No favorites yet",
                    style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 18),
                  ),
                ],
              ),
            )
          : MasonryGridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                // 倒序展示，最近收藏的在前面
                final wallpaper = favorites[favorites.length - 1 - index];
                return _buildWallpaperItem(context, wallpaper);
              },
            ),
    );
  }

  Widget _buildWallpaperItem(BuildContext context, Wallpaper wallpaper) {
    final double radius = context.read<AppState>().homeCornerRadius;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageDetailPage(wallpaper: wallpaper)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: colorScheme.surfaceContainerHighest,
          // 简单的阴影
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
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
                placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
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
