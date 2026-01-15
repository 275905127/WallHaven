// lib/models/image_source.dart
// ⚠️ 警示：内置源属于产品基线，禁止随意改 baseUrl/path 规则导致全站对接失效。
// ⚠️ 警示：认证方式以官方为准；不要在这里“猜”请求头。

class ImageSource {
  final String id;
  final String name;
  final String baseUrl;

  /// ✅ driver = “插件/驱动”标识（决定用哪套 API 适配器）
  /// 例如：wallhaven / waifuim / local / custom_v1 ...
  final String driver;

  /// Wallhaven 官方用 query param apikey
  final String? apiKey;

  final String? username;
  final bool isBuiltIn;

  const ImageSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.driver,
    this.apiKey,
    this.username,
    this.isBuiltIn = false,
  });

  /// ✅ 默认源不再“写死成业务假设”，但仍然可以作为内置插件的默认配置存在
  static const ImageSource wallhaven = ImageSource(
    id: 'wallhaven_official',
    name: 'Wallhaven',
    baseUrl: 'https://wallhaven.cc/api/v1',
    driver: 'wallhaven',
    isBuiltIn: true,
  );

  ImageSource copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? username,
    String? driver,
  }) {
    return ImageSource(
      id: id,
      isBuiltIn: isBuiltIn,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
      driver: driver ?? this.driver,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'driver': driver,
        'apiKey': apiKey,
        'username': username,
        'isBuiltIn': isBuiltIn,
      };

  factory ImageSource.fromJson(Map<String, dynamic> json) {
    // ✅ 兼容旧数据：没有 driver 的，一律当 wallhaven（不然直接炸用户存档）
    final drv = (json['driver'] as String?)?.trim();
    return ImageSource(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      baseUrl: (json['baseUrl'] as String?) ?? '',
      driver: (drv == null || drv.isEmpty) ? 'wallhaven' : drv,
      apiKey: (json['apiKey'] as String?),
      username: (json['username'] as String?),
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? false,
    );
  }
}