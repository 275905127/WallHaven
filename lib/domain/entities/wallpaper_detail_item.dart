// lib/domain/entities/wallpaper_detail_item.dart
import 'detail_field.dart';

class WallpaperDetailItem {
  final String sourceId;
  final String id;

  final Uri image;
  final int width;
  final int height;

  final Uri? shortUrl;
  final Uri? sourceUrl;

  final String? author;
  final Uri? authorAvatar;

  final int? views;
  final int? favorites;

  final String? resolution;
  final String? ratio;

  final int? fileSize;
  final String? fileType;

  final List<String> tags;
  final List<String> colors;

  /// ✅ 通用展示字段：UI 不再 hardcode “纯净度/分类”等语义
  final List<DetailField> fields;

  final Map<String, dynamic> extra;

  const WallpaperDetailItem({
    required this.sourceId,
    required this.id,
    required this.image,
    required this.width,
    required this.height,
    this.shortUrl,
    this.sourceUrl,
    this.author,
    this.authorAvatar,
    this.views,
    this.favorites,
    this.resolution,
    this.ratio,
    this.fileSize,
    this.fileType,
    required this.tags,
    required this.colors,
    required this.fields,
    this.extra = const {},
  });

  double get aspectRatio => height <= 0 ? 1.0 : width / height;
}