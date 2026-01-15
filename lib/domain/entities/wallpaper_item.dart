class WallpaperItem {
  final String sourceId; // SourceConfig.id
  final String id;

  final Uri preview; // 列表展示用（必有）
  final int width;
  final int height;

  final Uri? previewSmall; // 可选
  final Uri? original; // 可选

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
