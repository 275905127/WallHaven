class WallpaperItem {
  final String sourceId; // SourceConfig.id
  final String id;

  /// 列表展示用（必有：至少有一个可用的预览图）
  final Uri preview;

  final int width;
  final int height;

  /// 可选：更小的预览/占位
  final Uri? previewSmall;

  /// 可选：原图直链（有些源可能不给）
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

  /// ✅ 安全的展示 URL（永远不要返回 about:blank 这种假 URL）
  String get previewUrl => preview.toString();
}