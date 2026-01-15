import '../theme/theme_store.dart';
import 'http/http_client.dart';

import 'sources/wallpaper_source.dart';
import 'sources/wallhaven/wallhaven_source.dart';
import 'sources/generic_json/generic_json_source.dart';

class SourceFactory {
  final HttpClient http;

  SourceFactory({required this.http});

  /// 从 ThemeStore 当前 SourceConfig 生产 WallpaperSource
  WallpaperSource fromStore(ThemeStore store) {
    final cfg = store.currentSourceConfig;
    final pluginId = cfg.pluginId;

    // settings 一定要用“清洗后的”
    final settings = store.currentSettings;

    switch (pluginId) {
      case 'wallhaven':
        final baseUrl =
            (settings['baseUrl'] as String?)?.trim().isNotEmpty == true
                ? settings['baseUrl'] as String
                : 'https://wallhaven.cc';

        return WallhavenSource(
          sourceId: cfg.id,
          http: http,
          baseUrl: baseUrl,
          apiKey: (settings['apiKey'] as String?) ??
              (settings['apikey'] as String?),
        );

      case 'generic':
        return GenericJsonSource(
          sourceId: cfg.id,
          http: http,
          baseUrl: (settings['baseUrl'] as String?) ?? '',
          searchPath: (settings['searchPath'] as String?) ?? '/search',
          detailPath: (settings['detailPath'] as String?) ?? '/w/{id}',
          apiKey: (settings['apiKey'] as String?),
        );

      default:
        throw StateError('Unsupported pluginId: $pluginId');
    }
  }
}