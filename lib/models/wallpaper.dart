class Wallpaper {
  final String id;
  final String fullSizeUrl; // 原图地址 (用于详情页)
  final String thumbUrl;    // 缩略图地址 (用于列表页)
  final String resolution;  // 分辨率
  final int views;          // 浏览量
  final int favorites;      // 收藏量

  Wallpaper({
    required this.id,
    required this.fullSizeUrl,
    required this.thumbUrl,
    required this.resolution,
    required this.views,
    required this.favorites,
  });

  // 工厂方法：从 JSON 创建对象
  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'],
      // Wallhaven API 的 path 字段是原图
      fullSizeUrl: json['path'], 
      // thumbs.large 是大缩略图，适合瀑布流
      thumbUrl: json['thumbs']['large'], 
      resolution: json['resolution'],
      views: json['views'],
      favorites: json['favorites'],
    );
  }
}
