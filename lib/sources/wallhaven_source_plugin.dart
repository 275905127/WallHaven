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

  /// Wallhaven 站点根域
  static const String kSiteBase = 'https://wallhaven.cc';

  /// Wallhaven API v1 根地址（WallhavenSource 代码要求用这个）
  static const String kDefaultApiBaseUrl = '$kSiteBase/api/v1';

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
        // ✅ 必须是 api/v1，否则 data/sources/wallhaven/wallhaven_source.dart 会拼错路径
        'baseUrl': kDefaultApiBaseUrl,
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
      if (u.isEmpty) return kDefaultApiBaseUrl;

      if (!u.startsWith('http://') && !u.startsWith('https://')) {
        u = 'https://$u';
      }
      while (u.endsWith('/')) {
        u = u.substring(0, u.length - 1);
      }

      // ✅ 用户填 root /api /api/v1 都兜底到 /api/v1
      if (u.endsWith('/api/v1')) return u;

      if (u.endsWith('/api')) {
        return '$u/v1';
      }

      final uri = Uri.tryParse(u);
      final host = uri?.host.toLowerCase() ?? '';

      // 只要是 wallhaven 域且没写 /api/v1，就补齐
      if (host.contains('wallhaven.cc')) {
        return '$u/api/v1';
      }

      // 其它域名不乱补，尊重用户（但这样配错了就会在 UI/请求里暴露问题）
      return u;
    }

    String? normOpt(dynamic v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    s['baseUrl'] = normBaseUrl(s['baseUrl'] as String?);
    s['apiKey'] = normOpt(s['apiKey']);
    s['username'] = normOpt(s['username']);

    return s;
  }
}