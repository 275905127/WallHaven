class Wallpaper {
  final String id;
  final String url; // 原图链接
  final String thumb; // 大缩略图
  final String small; // 小缩略图
  final int width;
  final int height;
  final String ratio; // 比例

  Wallpaper({
    required this.id,
    required this.url,
    required this.thumb,
    required this.small,
    required this.width,
    required this.height,
    required this.ratio,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'],
      url: json['path'], // Wallhaven 原图路径字段
      thumb: json['thumbs']['large'], // 列表页用这个，清晰度够且省流
      small: json['thumbs']['small'],
      width: json['resolution'] != null ? int.tryParse(json['resolution'].split('x')[0]) ?? 0 : 0,
      height: json['resolution'] != null ? int.tryParse(json['resolution'].split('x')[1]) ?? 0 : 0,
      ratio: json['ratio'] ?? '16:9',
    );
  }
}
