class Wallpaper {
  final String id;
  final String thumbUrl;
  final String fullSizeUrl;
  final String resolution;
  final int views;
  final int favorites;
  // 新增：宽高比 (width / height)
  // 如果 API 没返回，默认给 1.0 (正方形)
  final double aspectRatio; 

  Wallpaper({
    required this.id,
    required this.thumbUrl,
    required this.fullSizeUrl,
    this.resolution = "",
    this.views = 0,
    this.favorites = 0,
    this.aspectRatio = 1.0, 
  });
}
