// lib/domain/entities/wallpaper_item.dart
class WallpaperItem {
  final String sourceId; // SourceConfig.id
  final String id;

  final Uri preview; // list display (required)
  final int width;
  final int height;

  final Uri? previewSmall;
  final Uri? original;

  final Map<String, dynamic> extra;

  const WallpaperItem({
    required this.sourceId,
    required this.id,
    required this.preview,
    required this.width,
    required this.height,
    this.previewSmall,
    this.original,
    this.extra = const {},
  });

  double get aspectRatio => height <= 0 ? 1.0 : width / height;
}