import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/http/http_client.dart';
import '../data/repository/wallpaper_repository.dart';
import '../data/source_factory.dart';
import '../domain/entities/detail_field.dart';
import '../domain/entities/wallpaper_detail_item.dart';
import '../domain/entities/wallpaper_item.dart';
import '../theme/theme_store.dart';

class WallpaperDetailPage extends StatefulWidget {
  final String id;
  final String? heroThumb;

  /// ✅ 推荐传进来：随机源没有 detail 时还能展示更多信息
  final WallpaperItem? item;

  const WallpaperDetailPage({
    super.key,
    required this.id,
    this.heroThumb,
    this.item,
  });

  @override
  State<WallpaperDetailPage> createState() => _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends State<WallpaperDetailPage> {
  bool _loading = true;
  WallpaperDetailItem? _detail;

  late final HttpClient _http;
  late final SourceFactory _factory;
  WallpaperRepository? _repo;

  bool _didInitDeps = false;

  @override
  void initState() {
    super.initState();
    _http = HttpClient();
    _factory = SourceFactory(http: _http);
    // ❌ 不要在 initState 里 ThemeScope.of(context)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDeps) return;
    _didInitDeps = true;

    final store = ThemeScope.of(context);
    _repo = WallpaperRepository(_factory.fromStore(store));

    // ✅ 现在再 load
    _load();
  }

  @override
  void dispose() {
    _http.dio.close(force: true);
    super.dispose();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) return;

    try {
      final store = ThemeScope.of(context);
      repo.setSource(_factory.fromStore(store));

      final d = await repo.detail(widget.id);
      if (!mounted) return;

      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _loading = false;
      });
    }
  }

  // 下面你的 build/工具函数都不用动
}

  Color _monoPrimary(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark ? Colors.white : Colors.black;
  }

  String _humanSize(int bytes) {
    if (bytes <= 0) return "-";
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;
    final b = bytes.toDouble();
    if (b >= gb) return "${(b / gb).toStringAsFixed(2)} GB";
    if (b >= mb) return "${(b / mb).toStringAsFixed(2)} MB";
    if (b >= kb) return "${(b / kb).toStringAsFixed(2)} KB";
    return "$bytes B";
  }

  List<DetailField> _fallbackFieldsFromItem(WallpaperItem? item) {
    if (item == null) return const [];
    final out = <DetailField>[];

    void add(String k, String label, dynamic v) {
      final s = v?.toString().trim() ?? '';
      if (s.isEmpty) return;
      out.add(DetailField(key: k, label: label, value: s));
    }

    add('id', 'ID', item.id);
    add('sourceId', '图源', item.sourceId);
    add('width', '宽', item.width > 0 ? item.width : null);
    add('height', '高', item.height > 0 ? item.height : null);

    // extra 尽量“挑可读的”
    final e = item.extra;
    for (final k in [
      'author',
      'uploader',
      'username',
      'source',
      'short_url',
      'shortUrl',
      'views',
      'favorites',
      'rating',
      'category',
      'resolution',
      'file_type',
      'fileType',
      'file_size',
      'fileSize'
    ]) {
      if (e.containsKey(k)) add(k, k, e[k]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final store = ThemeScope.of(context);
    final mono = _monoPrimary(context);

    final d = _detail;

    final imageUrl = d?.image.toString() ??
        widget.item?.original?.toString() ??
        widget.item?.preview.toString() ??
        (widget.heroThumb ?? '');

    final w = d?.width ?? (widget.item?.width ?? 0);
    final h = d?.height ?? (widget.item?.height ?? 0);
    final aspect = (w > 0 && h > 0) ? (w / h) : 16 / 9;

    final fields = (d?.fields.isNotEmpty == true) ? d!.fields : _fallbackFieldsFromItem(widget.item);

    final tags = d?.tags ?? const <String>[];
    final colors = d?.colors ?? const <String>[];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(store.cardRadius),
                child: AspectRatio(
                  aspectRatio: aspect.clamp(0.5, 2.4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(
                      color: theme.cardColor,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined, color: mono.withAlpha(89)), // 0.35 * 255
                    ),
                    errorWidget: (c, u, e) => Container(
                      color: theme.cardColor,
                      alignment: Alignment.center,
                      child: Icon(Icons.error_outline, color: mono.withAlpha(89)), // 0.35 * 255
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 信息卡
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(store.cardRadius),
                  border: Border.all(color: mono.withAlpha(26)), // 0.10 * 255
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "信息",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final f in fields) _metaLine(context, f.label, _prettyValue(f)),
                    if (d?.fileSize != null) _metaLine(context, "大小(人类可读)", _humanSize(d!.fileSize!)),
                  ],
                ),
              ),

              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                _chipsPanel(context, title: "标签", chips: tags),
              ],

              if (colors.isNotEmpty) ...[
                const SizedBox(height: 14),
                _chipsPanel(context, title: "颜色", chips: colors.map((e) => e.toUpperCase()).toList()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _prettyValue(DetailField f) {
    // 特殊处理 file_size 这种
    if (f.key == 'file_size' || f.key == 'fileSize') {
      final n = int.tryParse(f.value);
      if (n != null) return "${f.value} (${_humanSize(n)})";
    }
    return f.value;
  }

  Widget _metaLine(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: mono.withAlpha(140)), // 0.55 * 255
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(217), // 0.85 * 255
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                height: 1.25,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsPanel(BuildContext context, {required String title, required List<String> chips}) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);

    Widget chip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: mono.withAlpha(41)), // 0.16 * 255
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            height: 1.0,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(store.cardRadius),
        border: Border.all(color: mono.withAlpha(26)), // 0.10 * 255
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips.map(chip).toList(),
          ),
        ],
      ),
    );
  }
}