import '../../domain/search/query_spec.dart';

class GenericQueryAdapter {
  static Map<String, dynamic> toParams(QuerySpec q) {
    // generic 不保证支持 wallhaven 这些参数，所以只给“最通用”的
    final params = <String, dynamic>{};

    if (q.text.trim().isNotEmpty) params['q'] = q.text.trim();
    if (q.atleast.trim().isNotEmpty) params['atleast'] = q.atleast.trim();
    if (q.colorHex.trim().isNotEmpty) params['color'] = q.colorHex.trim().replaceAll('#', '');

    // 其余的如果你的 generic 服务端支持，可以自己扩展映射
    return params;
  }
}
