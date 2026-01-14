// ⚠️ 警示：内置源属于产品基线，禁止随意改 baseUrl/path 规则导致全站对接失效。
// ⚠️ 警示：认证方式以官方为准；不要在这里“猜”请求头。

class ImageSource {
  final String id;
  final String name;
  final String baseUrl;

  /// Wallhaven 官方用 query param apikey
  final String? apiKey;

  final String? username;
  final bool isBuiltIn;

  const ImageSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey,
    this.username,
    this.isBuiltIn = false,
  });

  static const ImageSource wallhaven = ImageSource(
    id: 'wallhaven_official',
    name: 'Wallhaven',
    baseUrl: 'https://wallhaven.cc/api/v1',
    isBuiltIn: true,
  );

  ImageSource copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? username,
  }) {
    return ImageSource(
      id: id,
      isBuiltIn: isBuiltIn,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'username': username,
        'isBuiltIn': isBuiltIn,
      };

  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      baseUrl: (json['baseUrl'] as String?) ?? '',
      apiKey: (json['apiKey'] as String?),
      username: (json['username'] as String?),
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? false,
    );
  }
}