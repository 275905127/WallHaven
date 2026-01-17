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

    // ✅ 只从 store.currentSettings 取（ThemeStore 已经 sanitize）
    final settings = store.currentSettings;

    switch (pluginId) {
      case 'wallhaven':
        {
          // ThemeStore/WallhavenSourcePlugin 已保证尽量是 https://wallhaven.cc/api/v1
          final baseUrl = (settings['baseUrl'] as String?)?.trim() ?? '';
          if (baseUrl.isEmpty) {
            final raw = cfg.settings['baseUrl'];
            throw StateError(
              'Wallhaven baseUrl is empty. '
              'configId=${cfg.id}, rawBaseUrl=$raw',
            );
          }

          final apiKey = (settings['apiKey'] as String?)?.trim();
          return WallhavenSource(
            sourceId: cfg.id,
            http: http,
            baseUrl: baseUrl,
            apiKey: (apiKey != null && apiKey.isNotEmpty) ? apiKey : null,
          );
        }

      case 'generic':
        {
          final baseUrl = (settings['baseUrl'] as String?)?.trim() ?? '';
          if (baseUrl.isEmpty) {
            throw StateError(
              'Generic JSON baseUrl is empty. '
              'configId=${cfg.id}, name=${cfg.name}',
            );
          }

          final searchPath = (settings['searchPath'] as String?)?.trim() ?? '';
          final detailPath = (settings['detailPath'] as String?)?.trim() ?? '';

          final apiKey = (settings['apiKey'] as String?)?.trim();
          return GenericJsonSource(
            sourceId: cfg.id,
            http: http,
            baseUrl: baseUrl,
            searchPath: searchPath,
            detailPath: detailPath,
            settings: settings,
            apiKey: (apiKey != null && apiKey.isNotEmpty) ? apiKey : null,
          );
        }

      default:
        throw StateError(
          'Unsupported pluginId: $pluginId. '
          'configId=${cfg.id}, name=${cfg.name}. '
          'Did you forget to register plugin in SourceRegistry?',
        );
    }
  }
}