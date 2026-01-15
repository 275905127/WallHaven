// lib/pages/wallpaper_detail_page.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/http/http_client.dart';
import '../data/repository/wallpaper_repository.dart';
import '../data/source_factory.dart';
import '../domain/entities/detail_field.dart';
import '../domain/entities/wallpaper_detail_item.dart';
import '../theme/theme_store.dart';

class WallpaperDetailPage extends StatefulWidget {
  final String id;
  final String? heroThumb;

  const WallpaperDetailPage({
    super.key,
    required this.id,
    this.heroThumb,
  });

  @override
  State<WallpaperDetailPage> createState() => _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends State<WallpaperDetailPage> {
  WallpaperDetailItem? _detail;
  bool _loading = true;
  String? _error;

  late final HttpClient _http;
  late final SourceFactory _factory;
  late final WallpaperRepository _repo;

  @override
  void initState() {
    super.initState();
    _http = HttpClient();
    _factory = SourceFactory(http: _http);
    _repo = WallpaperRepository(_factory.fromStore(ThemeScope.of(context)));
    _load();
  }

  @override
  void dispose() {
    _http.dio.close(force: true);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final store = ThemeScope.of(context);
      _repo.setSource(_factory.fromStore(store));

      final d = await _repo.detail(widget.id);
      if (!mounted) return;

      if (d == null) {
        setState(() {
          _detail = null;
          _loading = false;
          _error = '加载失败';
        });
        return;
      }

      setState(() {
        _detail = d;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detail = null;
        _loading = false;
        _error = '加载失败：$e';
      });
    }
  }

  Color _monoPrimary(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark ? Colors.white : Colors.black;
  }

  Future<void> _copy(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: t));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
  }

  List<DetailField> _normalizedFields(WallpaperDetailItem d) {
    // source.fields 优先，下面只补“缺的”
    final out = <DetailField>[];
    final seen = <String>{};

    void mark(DetailField f) {
      final k = f.key.trim();
      if (k.isNotEmpty) seen.add(k);
      out.add(f);
    }

    for (final f in d.fields) {
      if (f.displayValue.trim().isEmpty || f.displayValue == '-') continue;
      mark(f);
    }

    void addIf(DetailField f) {
      if (seen.contains(f.key)) return;
      if (f.displayValue.trim().isEmpty || f.displayValue == '-') return;
      mark(f);
    }

    addIf(DetailField.text(key: 'author', label: '作者', raw: d.author ?? ''));
    addIf(DetailField.text(
      key: 'resolution',
      label: '分辨率',
      raw: d.resolution ?? ((d.width > 0 && d.height > 0) ? '${d.width}x${d.height}' : ''),
    ));
    addIf(DetailField.text(key: 'ratio', label: '比例', raw: d.ratio ?? ''));
    addIf(DetailField.text(key: 'file_type', label: '格式', raw: d.fileType ?? ''));
    if (d.views != null) addIf(DetailField.number(key: 'views', label: '浏览量', value: d.views!));
    if (d.favorites != null) addIf(DetailField.number(key: 'favorites', label: '收藏量', value: d.favorites!));
    if (d.fileSize != null) addIf(DetailField.bytes(key: 'file_size', label: '大小', value: d.fileSize!));
    if (d.shortUrl != null && d.shortUrl.toString().trim().isNotEmpty) {
      addIf(DetailField.url(key: 'short_url', label: '短链', value: d.shortUrl.toString()));
    }
    if (d.sourceUrl != null && d.sourceUrl.toString().trim().isNotEmpty) {
      addIf(DetailField.url(key: 'source_url', label: '来源', value: d.sourceUrl.toString()));
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overlay = SystemUiOverlayStyle(
      statusBarColor: theme.scaffoldBackgroundColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: const Text('详情'),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_detail == null)
                  ? _ErrorView(
                      message: _error ?? '加载失败',
                      onRetry: _load,
                    )
                  : _body(context, _detail!),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WallpaperDetailItem d) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);

    final imageUrl = d.image.toString().isNotEmpty ? d.image.toString() : (widget.heroThumb ?? '');
    final aspect = (d.width > 0 && d.height > 0) ? (d.width / d.height) : (16 / 9);

    final fields = _normalizedFields(d);

    final canCopyImage = imageUrl.trim().isNotEmpty;
    final canCopyId = d.id.trim().isNotEmpty;

    return SingleChildScrollView(
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
                  child: Icon(Icons.image_outlined, color: mono.withOpacity(0.35)),
                ),
                errorWidget: (c, u, e) => Container(
                  color: theme.cardColor,
                  alignment: Alignment.center,
                  child: Icon(Icons.error_outline, color: mono.withOpacity(0.35)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(store.cardRadius),
              border: Border.all(color: mono.withOpacity(0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (d.author?.trim().isNotEmpty == true) ? d.author!.trim() : '未知作者',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (canCopyId)
                      _ActionChip(
                        icon: Icons.fingerprint,
                        label: '复制ID',
                        onTap: () => _copy(d.id),
                      ),
                    if (canCopyImage)
                      _ActionChip(
                        icon: Icons.image_outlined,
                        label: '复制图片链接',
                        onTap: () => _copy(imageUrl),
                      ),
                  ],
                ),

                if (fields.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: mono.withOpacity(0.10)),
                  const SizedBox(height: 8),
                  ...fields.map((f) => _MetaLine(
                        icon: _iconForFieldType(f.type),
                        label: f.label,
                        value: f.displayValue,
                        isUrl: f.type == DetailFieldType.url,
                        onCopy: () => _copy(f.copyValue),
                      )),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          _ChipPanel(title: '标签', emptyText: '暂无', chips: d.tags),
          const SizedBox(height: 14),
          _ChipPanel(title: '颜色', emptyText: '暂无', chips: d.colors.map((e) => e.toUpperCase()).toList()),
        ],
      ),
    );
  }

  IconData _iconForFieldType(DetailFieldType t) {
    switch (t) {
      case DetailFieldType.url:
        return Icons.link;
      case DetailFieldType.bytes:
        return Icons.storage_outlined;
      case DetailFieldType.number:
        return Icons.numbers;
      case DetailFieldType.text:
        return Icons.info_outline;
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: theme.iconTheme.color),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.iconTheme.color),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isUrl;
  final VoidCallback onCopy;

  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.isUrl,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    final valueStyle = TextStyle(
      fontSize: 14,
      height: 1.25,
      color: isUrl ? mono.withOpacity(0.85) : theme.textTheme.bodyLarge?.color,
      decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
      decorationColor: mono.withOpacity(0.25),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: mono.withOpacity(0.55)),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                height: 1.25,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value, style: valueStyle)),
          const SizedBox(width: 6),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.copy, size: 18, color: theme.iconTheme.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipPanel extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<String> chips;

  const _ChipPanel({
    required this.title,
    required this.emptyText,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = ThemeScope.of(context);
    final mono = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    Future<void> copy(BuildContext ctx, String text) async {
      final t = text.trim();
      if (t.isEmpty) return;
      await Clipboard.setData(ClipboardData(text: t));
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('已复制')));
    }

    Widget chip(String text) {
      return InkWell(
        onTap: () => copy(context, text),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: mono.withOpacity(0.16)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.0,
              color: theme.textTheme.bodyLarge?.color,
            ),
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
        border: Border.all(color: mono.withOpacity(0.10)),
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
          if (chips.isEmpty)
            Text(emptyText, style: TextStyle(color: theme.textTheme.bodyMedium?.color))
          else
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