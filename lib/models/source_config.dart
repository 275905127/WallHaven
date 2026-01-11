class SourceConfig {
  final String name;      // 图源名称 (如 "My Wallhaven")
  final String baseUrl;   // API 地址 (如 "https://wallhaven.cc/api/v1/search")
  final String apiKeyParam; // API Key 的参数名 (如 "apikey" 或 "key")
  final String apiKey;    // 用户的 Key
  
  // === JSON 解析规则 (JSONPath 简单版) ===
  // 告诉 App 数据在 JSON 的哪里
  final String listKey;   // 列表数据在哪？ (例如 "data")
  final String thumbKey;  // 缩略图字段名 (例如 "thumbs.large")
  final String fullKey;   // 原图字段名 (例如 "path")
  final String idKey;     // ID 字段名 (例如 "id")

  SourceConfig({
    required this.name,
    required this.baseUrl,
    this.apiKeyParam = 'apikey',
    this.apiKey = '',
    this.listKey = 'data',          // 默认适配 Wallhaven 结构
    this.thumbKey = 'thumbs.large',
    this.fullKey = 'path',
    this.idKey = 'id',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'baseUrl': baseUrl,
    'apiKeyParam': apiKeyParam,
    'apiKey': apiKey,
    'listKey': listKey,
    'thumbKey': thumbKey,
    'fullKey': fullKey,
    'idKey': idKey,
  };

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      name: json['name'],
      baseUrl: json['baseUrl'],
      apiKeyParam: json['apiKeyParam'] ?? 'apikey',
      apiKey: json['apiKey'] ?? '',
      listKey: json['listKey'] ?? 'data',
      thumbKey: json['thumbKey'] ?? 'thumbs.large',
      fullKey: json['fullKey'] ?? 'path',
      idKey: json['idKey'] ?? 'id',
    );
  }
}
