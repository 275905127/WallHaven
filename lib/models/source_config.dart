// 定义单个选项
class FilterOption {
  final String label; // 显示的名字，如 "动漫"
  final String value; // 传给 API 的值，如 "010"

  FilterOption({required this.label, required this.value});

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
  factory FilterOption.fromJson(Map<String, dynamic> json) => 
      FilterOption(label: json['label'], value: json['value']);
}

// 定义一组筛选 (如 "分类" 组)
class FilterGroup {
  final String title;     // 标题，如 "分类"
  final String paramName; // URL参数名，如 "categories"
  final String type;      // 类型：'radio' (单选), 'checkbox' (多选-逗号分隔), 'bitmask' (Wallhaven专用)
  final List<FilterOption> options;

  FilterGroup({
    required this.title,
    required this.paramName,
    required this.type,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'paramName': paramName,
    'type': type,
    'options': options.map((e) => e.toJson()).toList(),
  };

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(
      title: json['title'],
      paramName: json['paramName'],
      type: json['type'] ?? 'radio',
      options: (json['options'] as List).map((e) => FilterOption.fromJson(e)).toList(),
    );
  }
}

class SourceConfig {
  final String name;
  final String baseUrl;
  final String apiKeyParam;
  final String apiKey;
  
  final String listKey;
  final String thumbKey;
  final String fullKey;
  final String idKey;

  // === 核心变化：不再是死板的 filterType，而是动态的 filters 列表 ===
  final List<FilterGroup> filters; 

  SourceConfig({
    required this.name,
    required this.baseUrl,
    this.apiKeyParam = 'apikey',
    this.apiKey = '',
    this.listKey = 'data',
    this.thumbKey = 'thumbs.large',
    this.fullKey = 'path',
    this.idKey = 'id',
    this.filters = const [], // 默认为空
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
    'filters': filters.map((e) => e.toJson()).toList(),
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
      filters: json['filters'] != null 
          ? (json['filters'] as List).map((e) => FilterGroup.fromJson(e)).toList()
          : [],
    );
  }
}
