// ⚠️ 警示：此模型的字段映射必须跟随 Wallhaven 官方返回结构，禁止“想当然”改字段名。
// ⚠️ 警示：列表/详情两套 JSON 不同；不要用同一个 factory 乱吃字段。

class Wallpaper {
  final String id;

  /// 原图直链（detail/search 都有 path）
  final String url;

  /// 缩略图（search 有 thumbs）
  final String thumb;
  final String small;

  final int width;
  final int height;
  final String ratio;

  const Wallpaper({
    required this.id,
    required this.url,
    required this.thumb,
    required this.small,
    required this.width,
    required this.height,
    required this.ratio,
  });

  factory Wallpaper.fromSearchJson(Map<String, dynamic> json) {
    final resolution = (json['resolution'] as String?) ?? '';
    int w = 0;
    int h = 0;
    if (resolution.contains('x')) {
      final parts = resolution.split('x');
      if (parts.length == 2) {
        w = int.tryParse(parts[0]) ?? 0;
        h = int.tryParse(parts[1]) ?? 0;
      }
    }

    final thumbs = (json['thumbs'] as Map?)?.cast<String, dynamic>();
    final largeThumb = (thumbs?['large'] as String?) ?? '';
    final smallThumb = (thumbs?['small'] as String?) ?? '';

    return Wallpaper(
      id: (json['id'] as String?) ?? '',
      url: (json['path'] as String?) ?? '',
      thumb: largeThumb,
      small: smallThumb,
      width: w,
      height: h,
      ratio: (json['ratio'] as String?) ?? '',
    );
  }
}

class WallpaperDetail {
  final String id;
  final String url; // path
  final int width;
  final int height;

  final String? source;
  final String? shortUrl;

  final int? views;
  final int? favorites;

  final String? purity; // sfw / sketchy / nsfw
  final String? category; // general / anime / people
  final String? resolution; // "1920x1080"
  final String? ratio; // "16x9"

  final int? fileSize; // bytes
  final String? fileType;

  final List<String> tags; // 标签名列表（中文展示在 UI 层处理）
  final List<String> colors; // hex 列表（不用于 UI 上色，只展示）

  final String? uploader; // username
  final String? uploaderAvatar; // avatar

  const WallpaperDetail({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    this.source,
    this.shortUrl,
    this.views,
    this.favorites,
    this.purity,
    this.category,
    this.resolution,
    this.ratio,
    this.fileSize,
    this.fileType,
    required this.tags,
    required this.colors,
    this.uploader,
    this.uploaderAvatar,
  });

  factory WallpaperDetail.fromDetailJson(Map<String, dynamic> json) {
    final tagsJson = (json['tags'] as List?) ?? const [];
    final tags = tagsJson
        .map((e) => (e is Map<String, dynamic>) ? (e['name'] as String?) : null)
        .whereType<String>()
        .toList();

    final colorsJson = (json['colors'] as List?) ?? const [];
    final colors = colorsJson.map((e) => e?.toString()).whereType<String>().toList();

    final uploaderJson = (json['uploader'] as Map?)?.cast<String, dynamic>();
    final avatarJson = (uploaderJson?['avatar'] as Map?)?.cast<String, dynamic>();

    return WallpaperDetail(
      id: (json['id'] as String?) ?? '',
      url: (json['path'] as String?) ?? '',
      width: (json['dimension_x'] as int?) ?? 0,
      height: (json['dimension_y'] as int?) ?? 0,
      source: (json['source'] as String?),
      shortUrl: (json['short_url'] as String?),
      views: (json['views'] as int?),
      favorites: (json['favorites'] as int?),
      purity: (json['purity'] as String?),
      category: (json['category'] as String?),
      resolution: (json['resolution'] as String?),
      ratio: (json['ratio'] as String?),
      fileSize: (json['file_size'] as int?),
      fileType: (json['file_type'] as String?),
      tags: tags,
      colors: colors,
      uploader: (uploaderJson?['username'] as String?),
      uploaderAvatar: (avatarJson?['200px'] as String?) ?? (avatarJson?['128px'] as String?),
    );
  }
}