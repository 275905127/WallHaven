class ImageSource {
  final String id;
  final String name;
  final String baseUrl;
  final String? apiKey;    // API Key
  final String? username;  // 🌟 新增：用户名
  final bool isBuiltIn;    // 是否内置

  const ImageSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.apiKey,
    this.username,
    this.isBuiltIn = false,
  });

  // 🌟 Wallhaven 完美接入配置
  static const ImageSource wallhaven = ImageSource(
    id: 'wallhaven_official',
    name: 'Wallhaven',
    baseUrl: 'https://wallhaven.cc/api/v1', 
    isBuiltIn: true,
  );

  // 🌟 辅助方法：复制并修改 (用于更新操作)
  ImageSource copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? username,
  }) {
    return ImageSource(
      id: id, // ID 保持不变
      isBuiltIn: isBuiltIn, // 内置属性保持不变
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      username: username ?? this.username,
    );
  }

  // 序列化逻辑 (保存到本地)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey, 
    'username': username, // 保存用户名
    'isBuiltIn': isBuiltIn,
  };

  // 反序列化逻辑 (从本地读取)
  factory ImageSource.fromJson(Map<String, dynamic> json) {
    return ImageSource(
      id: json['id'],
      name: json['name'],
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'],
      username: json['username'], // 读取用户名
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }

  // 辅助方法：生成带 Key 的请求头
  Map<String, String> get headers {
    final Map<String, String> h = {};
    if (apiKey != null && apiKey!.isNotEmpty) {
      h['X-API-Key'] = apiKey!;
    }
    return h;
  }
}
