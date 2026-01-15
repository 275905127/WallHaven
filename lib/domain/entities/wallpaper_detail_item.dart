class WallpaperDetailItem {
  final String sourceId;
  final String id;

  final Uri image; // 原图或可用大图
  final int width;
  final int height;

  final String? author;
  final Uri? authorAvatar;

  final Uri? shortUrl;
  final Uri? sourceUrl;

  final int? views;
  final int? favorites;

  final String? category; // domain 里用 string（不强行枚举，避免绑死）
  final String? rating;   // sfw/sketchy/nsfw 或其他源自定义

  final String? resolution; // "1920x1080"
  final String? ratio;      // "16x9"

  final int? fileSize;
  final String? fileType;

  final List<String> tags;
  final List<String> colors;

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
    this.category,
    this.rating,
    this.resolution,
    this.ratio,
    this.fileSize,
    this.fileType,
    this.tags = const [],
    this.colors = const [],
    this.extra = const {},
  });

  double get aspectRatio => height <= 0 ? 1.0 : width / height;
}