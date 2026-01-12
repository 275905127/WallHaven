class Wallpaper {
  final String id;
  final String thumbUrl;
  final String fullSizeUrl;
  final String resolution;
  final int views;
  final int favorites;
  final double aspectRatio; 
  final String purity; // 新增：分级 (sfw, sketchy, nsfw)
  final Map<String, dynamic> metadata;

  Wallpaper({
    required this.id,
    required this.thumbUrl,
    required this.fullSizeUrl,
    this.resolution = "",
    this.views = 0,
    this.favorites = 0,
    this.aspectRatio = 1.0, 
    this.purity = "sfw", // 默认为 sfw
    this.metadata = const {},
  });

  // 用于“我的收藏”本地存储
  Map<String, dynamic> toJson() => {
    'id': id,
    'thumbUrl': thumbUrl,
    'fullSizeUrl': fullSizeUrl,
    'resolution': resolution,
    'views': views,
    'favorites': favorites,
    'aspectRatio': aspectRatio,
    'purity': purity,
    'metadata': metadata,
  };

  // 用于从本地存储读取
  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'],
      thumbUrl: json['thumbUrl'],
      fullSizeUrl: json['fullSizeUrl'],
      resolution: json['resolution'] ?? "",
      views: json['views'] ?? 0,
      favorites: json['favorites'] ?? 0,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      purity: json['purity'] ?? "sfw",
      metadata: json['metadata'] ?? {},
    );
  }
}
