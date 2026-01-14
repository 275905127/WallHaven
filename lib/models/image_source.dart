class ImageSource {
  final String id;
  final String name;
  final String baseUrl;
  final bool isBuiltIn; // 是否内置

  const ImageSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.isBuiltIn = false,
  });

  // 🌟 Wallhaven 完美接入配置
  static const ImageSource wallhaven = ImageSource(
    id: 'wallhaven_official',
    name: 'Wallhaven',
    baseUrl: 'https://wallhaven.cc/api/v1', 
    isBuiltIn: true,
  );

  // 序列化逻辑 (用于保存到本地)
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'baseUrl': baseUrl, 'isBuiltIn': isBuiltIn,
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
