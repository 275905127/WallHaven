import 'package:dio/dio.dart';
import 'source_plugin.dart';
import '../api/wallhaven_api.dart';

class WallhavenSourcePlugin implements SourcePlugin {
  static const String kId = 'wallhaven';

  // 不要 const 绑死编译期常量，直接用 final
  static final String kDefaultBaseUrl = WallhavenClient.kDefaultBaseUrl;

  @override
  String get pluginId => kId;

  @override
  String get defaultName => 'Wallhaven';

  @override
  SourceConfig defaultConfig() {
    // ❌ 这里不能 const
    return SourceConfig(
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

    s['baseUrl'] = normBaseUrl((s['baseUrl'] as String?) ?? kDefaultBaseUrl);
    s['apiKey'] = normOpt(s['apiKey']);
    s['username'] = normOpt(s['username']);
    return s;
  }

  @override
  WallpaperSourceClient createClient({
    required Map<String, dynamic> settings,
    Dio? dio, // ✅ 必须跟接口一致
  }) {
    final fixed = sanitizeSettings(settings);
    final baseUrl = fixed['baseUrl'] as String;
    final apiKey = fixed['apiKey'] as String?;

    final c = WallhavenClient(
      dio: dio ?? Dio(),
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
    return WallhavenClientAdapter(c);
  }
}