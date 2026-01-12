class Wallpaper {
  final String id;
  final String thumbUrl;
  final String fullSizeUrl;
  final String resolution;
  final int views;
  final int favorites;
  final double aspectRatio; 
  // 新增：存储原始数据，用于详情页展示更多信息
  final Map<String, dynamic> metadata;

  Wallpaper({
    required this.id,
    required this.thumbUrl,
    required this.fullSizeUrl,
    this.resolution = "",
    this.views = 0,
    this.favorites = 0,
    this.aspectRatio = 1.0, 
    this.metadata = const {}, // 默认为空
  });
}
