/// lib/sources/simple_json_source_plugin.dart
///
/// Generic JSON 图源插件（自由配置）
/// - 支持两类：
///   1) 随机直链：listKey = "@direct"（通常不需要 searchPath/detailPath）
///   2) API 搜索/详情：需要 searchPath/detailPath
library simple_json_source_plugin;

import 'source_plugin.dart';

class SimpleJsonPlugin implements SourcePlugin {
  static const String kId = 'generic';

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Generic JSON';

  @override
  SourceConfig defaultConfig() {
    return const SourceConfig(
      id: 'default_generic',
      pluginId: kId,
      name: 'Generic JSON',
      settings: {
        'baseUrl': 'https://example.com/api',
        'listKey': '@direct', // ✅ 默认按“随机直链”理解
        'searchPath': '',     // ✅ 直链模式下通常为空
        'detailPath': '',     // ✅ 直链模式下通常为空
        'apiKey': null,
        'filters': [],
      },
    );
  }

  @override
  Map<String, dynamic> sanitizeSettings(Map<String, dynamic> raw) {
    final m = Map<String, dynamic>.from(raw);

    String normBaseUrl(String? url) {
      var u = (url ?? '').trim();
      if (u.isEmpty) return '';
      if (!u.startsWith('http://') && !u.startsWith('https://')) {
        u = 'https://$u';
      }
      while (u.endsWith('/')) {
        u = u.substring(0, u.length - 1);
      }
      return u;
    }

    String normPath(String? p) {
      var v = (p ?? '').trim();
      if (v.isEmpty) return '';
      if (!v.startsWith('/')) v = '/$v';
      return v;
    }

    String? normOpt(String? v) {
      final t = v?.trim();
      if (t == null || t.isEmpty) return null;
      return t;
    }

    String normListKey(dynamic v) {
      final t = (v is String) ? v.trim() : '';
      return t.isEmpty ? '@direct' : t;
    }

    List<dynamic> normFilters(dynamic v) {
      if (v is List) return v;
      return const [];
    }

    // baseUrl / apiKey
    m['baseUrl'] = normBaseUrl(m['baseUrl'] as String?);
    m['apiKey'] = normOpt(m['apiKey'] as String?);

    // 兼容 UI / 自由 JSON
    m['listKey'] = normListKey(m['listKey']);
    m['filters'] = normFilters(m['filters']);

    // ✅ 关键修正：
    // 如果是随机直链（@direct），不要强行补 search/detail
    final isDirect = (m['listKey'] as String) == '@direct';

    if (isDirect) {
      m['searchPath'] = normPath(m['searchPath'] as String?); // 保留用户输入；默认空
      m['detailPath'] = normPath(m['detailPath'] as String?); // 保留用户输入；默认空
    } else {
      // 非直链模式：你至少需要 search/detail 的默认值兜底
      final sp = normPath(m['searchPath'] as String?);
      final dp = normPath(m['detailPath'] as String?);
      m['searchPath'] = sp.isEmpty ? '/search' : sp;
      m['detailPath'] = dp.isEmpty ? '/w/{id}' : dp;
    }

    return m;
  }
}