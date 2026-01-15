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
      return GenericJsonSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: (settings['baseUrl'] as String?) ?? '',
        searchPath: (settings['searchPath'] as String?) ?? '/search',
        detailPath: (settings['detailPath'] as String?) ?? '/w/{id}',
        apiKey: (settings['apiKey'] as String?),
      );
    }

    throw StateError('Unsupported pluginId: $pluginId');
  }
}