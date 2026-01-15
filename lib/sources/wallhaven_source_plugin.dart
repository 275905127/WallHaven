// lib/sources/wallhaven_source_plugin.dart
import 'source_plugin.dart';

class WallhavenSourcePlugin implements SourcePlugin {
  static const String kId = 'wallhaven';

  // 这里别再依赖 WallhavenClient 常量：你要“彻底解耦”，就别把 api 层拖进来
  // Wallhaven 官方默认 baseUrl 就写死在配置层即可（风险：以后改域名，你只改这里/默认配置）
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

    String normBaseUrl(String v) {
      var u = v.trim();
      if (u.isEmpty) return kDefaultBaseUrl;
      if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
      while (u.endsWith('/')) u = u.substring(0, u.length - 1);
      return u;
    }

    String? normOpt(dynamic v) {
      if (v == null) return null;
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    // ✅ 配置层只负责“清洗”，不做请求、不做字段映射
    s['baseUrl'] = normBaseUrl((s['baseUrl'] as String?) ?? kDefaultBaseUrl);
    s['apiKey'] = normOpt(s['apiKey']);
    s['username'] = normOpt(s['username']);

    return s;
  }
}