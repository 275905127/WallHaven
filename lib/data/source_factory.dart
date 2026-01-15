import '../theme/theme_store.dart';
import 'http/http_client.dart';
import 'sources/generic_json/generic_json_source.dart';
import 'sources/wallhaven/wallhaven_source.dart';
import 'sources/wallpaper_source.dart';

class SourceFactory {
  final HttpClient http;

  SourceFactory({required this.http});

  WallpaperSource fromStore(ThemeStore store) {
    final cfg = store.currentSourceConfig;
    final pluginId = cfg.pluginId;
    final settings = store.currentSettings;

    if (pluginId == 'wallhaven') {
      return WallhavenSource(
        sourceId: cfg.id,
        http: http,
        apiKey: (settings['apiKey'] as String?) ?? (settings['apikey'] as String?),
      );
    }

    if (pluginId == 'generic') {
      final baseUrl = _normBaseUrl((settings['baseUrl'] as String?) ?? '');
      final searchPath = _normPath((settings['searchPath'] as String?) ?? '/search', fallback: '/search');
      final detailPath = _normPath((settings['detailPath'] as String?) ?? '/w/{id}', fallback: '/w/{id}');

      return GenericJsonSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: baseUrl,
        searchPath: searchPath,
        detailPath: detailPath,
        apiKey: (settings['apiKey'] as String?),
      );
    }

    throw StateError('Unsupported pluginId: $pluginId');
  }

  String _normBaseUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  String _normPath(String raw, {required String fallback}) {
    var p = raw.trim();
    if (p.isEmpty) p = fallback;
    if (!p.startsWith('/')) p = '/$p';
    return p;
  }
}