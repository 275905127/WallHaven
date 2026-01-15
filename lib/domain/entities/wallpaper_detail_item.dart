// lib/domain/entities/wallpaper_detail_item.dart
import 'detail_field.dart';

class WallpaperDetailItem {
  final String sourceId;
  final String id;

  final Uri image;
  final int width;
  final int height;

  final String? author;
  final Uri? authorAvatar;

  final Uri? shortUrl;
  final Uri? sourceUrl;

  final int? views;
  final int? favorites;

  final String? resolution;
  final String? ratio;

  final int? fileSize;
  final String? fileType;

  final List<String> tags;
  final List<String> colors;

  /// ✅ 通用详情展示字段：source 决定 label/value，UI 只渲染
  final List<DetailField> fields;

  final Map<String, dynamic> extra;

  const WallpaperDetailItem({
    required this.sourceId,
    required this.id,
    required this.image,
    required this.width,
    required this.height,

    this.author,
    this.authorAvatar,

    this.shortUrl,
    this.sourceUrl,

    this.views,
    this.favorites,

    this.resolution,
    this.ratio,

    this.fileSize,
    this.fileType,

    this.tags = const [],
    this.colors = const [],

    this.fields = const [],
    this.extra = const {},
  });

  double get aspectRatio => height <= 0 ? 1.0 : width / height;
}