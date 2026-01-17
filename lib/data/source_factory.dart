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
    final settings = store.currentSettings;

    if (pluginId == 'wallhaven') {
      // ✅ 与 WallhavenSourcePlugin 的默认值对齐（plugin 里是 https://wallhaven.cc）
      // 具体 API 路径应该由 WallhavenSource 自己拼（/api/v1/...），不要在这里塞进去。
      final baseUrl = (settings['baseUrl'] as String?)?.trim();
      final fixedBaseUrl = (baseUrl == null || baseUrl.isEmpty) ? 'https://wallhaven.cc' : baseUrl;

      return WallhavenSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: fixedBaseUrl,
        apiKey: (settings['apiKey'] as String?) ?? (settings['apikey'] as String?),
      );
    }

    if (pluginId == 'generic') {
      final baseUrl = (settings['baseUrl'] as String?)?.trim() ?? '';
      final listKey = (settings['listKey'] as String?)?.trim() ?? '@direct';
      final apiKey = (settings['apiKey'] as String?);

      // ✅ 明确分支：@direct = 随机直链模式
      if (listKey == '@direct') {
        return GenericJsonSource(
          sourceId: cfg.id,
          http: http,
          baseUrl: baseUrl,
          searchPath: '', // 直链模式不走搜索
          detailPath: '', // 直链模式不走详情
          settings: settings,
          apiKey: apiKey,
        );
      }

      // ✅ 非直链模式：需要 search/detail（由 sanitize 兜底，但这里再做一次保险）
      final searchPath = (settings['searchPath'] as String?)?.trim() ?? '';
      final detailPath = (settings['detailPath'] as String?)?.trim() ?? '';

      return GenericJsonSource(
        sourceId: cfg.id,
        http: http,
        baseUrl: baseUrl,
        searchPath: searchPath.isEmpty ? '/search' : searchPath,
        detailPath: detailPath.isEmpty ? '/w/{id}' : detailPath,
        settings: settings,
        apiKey: apiKey,
      );
    }

    throw StateError('Unsupported pluginId: $pluginId');
  }
}