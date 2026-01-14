class ImageSource {
  final String id;
  final String name;
  final String baseUrl;
  final String? apiKey; // 🌟 新增：支持 API Key (用于解锁 Wallhaven 高级内容)
  final bool isBuiltIn; // 是否内置

  const ImageSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey,
    this.isBuiltIn = false,
  });

  // 🌟 Wallhaven 完美接入配置
  // 官方文档: https://wallhaven.cc/help/api
  static const ImageSource wallhaven = ImageSource(
    id: 'wallhaven_official',
    name: 'Wallhaven',
    baseUrl: 'https://wallhaven.cc/api/v1', 
    isBuiltIn: true,
  );

  // 序列化逻辑 (保存到本地)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey, // 保存 Key
    'isBuiltIn': isBuiltIn,
  };

  // 反序列化逻辑 (从本地读取)
  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'], // 读取 Key
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }

  // 辅助方法：生成带 Key 的请求头 (预留给网络层使用)
  Map<String, String> get headers {
    if (apiKey != null && apiKey!.isNotEmpty) {
      return {'X-API-Key': apiKey!};
    }
    return {};
  }
}
