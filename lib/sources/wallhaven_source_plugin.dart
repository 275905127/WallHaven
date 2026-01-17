/// lib/sources/wallhaven_source_plugin.dart
///
/// Wallhaven 官方图源插件
/// - 只负责：
///   - 默认配置
///   - settings 清洗
/// - ❌ 不做任何网络请求
/// - ❌ 不 import data / client / dto
library wallhaven_source_plugin;

import 'source_plugin.dart';

class WallhavenSourcePlugin implements SourcePlugin {
  static const String kId = 'wallhaven';

  /// 官方默认站点
  /// 注意：这里只是“配置默认值”，
  /// 真正请求逻辑在 data/sources/wallhaven/*
  static const String kDefaultBaseUrl = 'https://wallhaven.cc';

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Wallhaven';

  @override
  SourceConfig defaultConfig() {
    return const SourceConfig(
      id: 'default_wallhaven',
      pluginId: kId,
      name: 'Wallhaven',
      settings: {
        'baseUrl': kDefaultBaseUrl,
        'apiKey': null,
        'username': null,
      },
    );
  }

  @override
  Map<String, dynamic> sanitizeSettings(Map<String, dynamic> raw) {
    final s = Map<String, dynamic>.from(raw);

    String normBaseUrl(String? v) {
      var u = (v ?? '').trim();
      if (u.isEmpty) return kDefaultBaseUrl;
      if (!u.startsWith('http://') && !u.startsWith('https://')) {
        u = 'https://$u';
      }
      while (u.endsWith('/')) {
        u = u.substring(0, u.length - 1);
      }
      return u;
    }

    String? normOpt(dynamic v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    // 只做“规范化”，不引入业务逻辑
    s['baseUrl'] = normBaseUrl(s['baseUrl'] as String?);
    s['apiKey'] = normOpt(s['apiKey']);
    s['username'] = normOpt(s['username']);

    return s;
  }
}