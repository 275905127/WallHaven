// lib/api/source_client.dart
//
// ✅ 兼容层：保留这个文件是为了不让历史 import 直接爆炸。
// ❌ 这里不再依赖 wallpaper.dart / wallhaven_api.dart
//
// 你的新架构已经走 domain + data 的 WallpaperSource 了。
// 这个文件只提供一个“统一客户端”接口（如果你某处旧代码还引用它）。

import 'package:dio/dio.dart';

import '../domain/entities/filter_spec.dart';
import '../domain/entities/search_query.dart';
import '../domain/entities/source_capabilities.dart';
import '../domain/entities/source_kind.dart';
import '../domain/entities/wallpaper_detail_item.dart';
import '../domain/entities/wallpaper_item.dart';

/// 统一客户端能力（兼容旧 import 用）
/// - 分页源：实现 search
/// - 随机源：实现 random
/// - 详情：可选 detail
abstract class WallpaperSourceClient {
  SourceKind get kind;
  SourceCapabilities get capabilities;

  Future<List<WallpaperItem>> search({required SearchQuery query});

  Future<WallpaperItem?> random({required FilterSpec filters});

  Future<WallpaperDetailItem?> detail({required String id});
}

/// 一个简单的函数式适配器（可选用）
/// 你可以用它把任意实现“包”成 WallpaperSourceClient，避免到处写 class。
class FuncWallpaperSourceClient implements WallpaperSourceClient {
  final Dio dio;

  final SourceKind _kind;
  final SourceCapabilities _capabilities;

  final Future<List<WallpaperItem>> Function(SearchQuery) _search;
  final Future<WallpaperItem?> Function(FilterSpec) _random;
  final Future<WallpaperDetailItem?> Function(String) _detail;

  FuncWallpaperSourceClient({
    required this.dio,
    required SourceKind kind,
    required SourceCapabilities capabilities,
    Future<List<WallpaperItem>> Function(SearchQuery)? search,
    Future<WallpaperItem?> Function(FilterSpec)? random,
    Future<WallpaperDetailItem?> Function(String)? detail,
  })  : _kind = kind,
        _capabilities = capabilities,
        _search = (search ?? ((_) async => const [])),
        _random = (random ?? ((_) async => null)),
        _detail = (detail ?? ((_) async => null));

  @override
  SourceKind get kind => _kind;

  @override
  SourceCapabilities get capabilities => _capabilities;

  @override
  Future<List<WallpaperItem>> search({required SearchQuery query}) => _search(query);

  @override
  Future<WallpaperItem?> random({required FilterSpec filters}) => _random(filters);

  @override
  Future<WallpaperDetailItem?> detail({required String id}) => _detail(id);
}