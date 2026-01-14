class ImageSource {
  final String id;
  final String name;
  final String baseUrl;
  final bool isBuiltIn; // 是否为内置 (如 Wallhaven)

  const ImageSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.isBuiltIn = false,
  });

  // 🌟 内置默认图源：Wallhaven
  static const ImageSource wallhaven = ImageSource(
    id: 'wallhaven_official',
    name: 'Wallhaven',
    baseUrl: 'https://wallhaven.cc/api/v1', // 真实 API 地址
    isBuiltIn: true,
  );

  // 序列化 (用于保存到本地)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'isBuiltIn': isBuiltIn,
  };

  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }
}
