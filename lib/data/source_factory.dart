// lib/data/source_factory.dart
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

    // ✅ 重要：一定用 sanitize 过的 settings
    final settings = store.currentSettings;

    if (pluginId == 'wallhaven') {
      return WallhavenSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: (settings['baseUrl'] as String?) ?? 'https://wallhaven.cc/api/v1',
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
        apiKey: (settings['apiKey'] as String?) ?? (settings['apikey'] as String?),
        settings: settings, // ✅ 传入 settings，让 GenericJson 读取 capabilities/mapping/detailFields
      );
    }

    throw StateError('Unsupported pluginId: $pluginId');
  }
}