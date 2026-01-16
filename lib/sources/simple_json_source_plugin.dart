// lib/sources/simple_json_source_plugin.dart
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
        'searchPath': '/search',
        'detailPath': '/w/{id}',
        'apiKey': null,
      },
    );
  }

  @override
Map<String, dynamic> sanitizeSettings(Map<String, dynamic> s) {
  final m = Map<String, dynamic>.from(s);

  String normBaseUrl(String? url) {
    var u = (url ?? '').trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  String normPath(String? p, String fallback) {
    var v = (p ?? fallback).trim();
    if (v.isEmpty) v = fallback;
    if (!v.startsWith('/')) v = '/$v';
    return v;
  }

  String? normOpt(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  m['baseUrl'] = normBaseUrl(m['baseUrl'] as String?);
  m['searchPath'] = normPath(m['searchPath'] as String?, '/search');
  m['detailPath'] = normPath(m['detailPath'] as String?, '/w/{id}');
  m['apiKey'] = normOpt(m['apiKey'] as String?);

  return m;
}