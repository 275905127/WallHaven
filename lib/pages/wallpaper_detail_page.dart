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

  /// 列表页传进来的预览图（可选：用于更快看到图）
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

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制')),
    );
  }

  List<DetailField> _normalizedFields(WallpaperDetailItem d) {
    // ✅ 把“常用字段”统一补齐到 fields（但不引入 wallhaven 语义）
    // 规则：已有同 key 的不重复；空值不加；fileSize 做友好展示
    final out = <DetailField>[];
    final seen = <String>{};

    void addIf(String key, String label, String? value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) return;
      if (seen.contains(key)) return;
      seen.add(key);
      out.add(DetailField(key: key, label: label, value: v));
    }

    // 先放 source 自己给的 fields（优先级更高）
    for (final f in d.fields) {
      final k = f.key.trim();
      if (k.isNotEmpty) seen.add(k);
      out.add(f);
    }

    addIf('author', '作者', d.author);
    addIf('resolution', '分辨率', d.resolution ?? ((d.width > 0 && d.height > 0) ? '${d.width}x${d.height}' : null));
    addIf('ratio', '比例', d.ratio);
    addIf('file_type', '格式', d.fileType);
    addIf('views', '浏览量', d.views?.toString());
    addIf('favorites', '收藏量', d.favorites?.toString());
    addIf('file_size', '大小', d.fileSize == null ? null : _humanSize(d.fileSize!));
    addIf('short_url', '短链', d.shortUrl?.toString());
    addIf('source_url', '来源', d.sourceUrl?.toString());

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

    // 仅当存在可复制内容才显示动作
    final canCopyImage = imageUrl.trim().isNotEmpty;
    final canCopyId = d.id.trim().isNotEmpty;
    final canCopyShort = (d.shortUrl?.toString() ?? '').trim().isNotEmpty;
    final canCopySource = (d.sourceUrl?.toString() ?? '').trim().isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
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

          // Header card: basic + actions
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
                _HeaderLine(
                  title: d.author?.trim().isNotEmpty == true ? d.author!.trim() : '未知作者',
                  subtitle: d.sourceId.trim().isEmpty ? null : 'Source: ${d.sourceId}',
                ),
                const SizedBox(height: 10),

                // actions (only show if meaningful)
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
                    if (canCopyShort)
                      _ActionChip(
                        icon: Icons.link,
                        label: '复制短链',
                        onTap: () => _copy(d.shortUrl.toString()),
                      ),
                    if (canCopySource)
                      _ActionChip(
                        icon: Icons.public,
                        label: '复制来源链接',
                        onTap: () => _copy(d.sourceUrl.toString()),
                      ),
                  ],
                ),

                if (fields.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DividerLine(color: mono.withOpacity(0.10)),
                  const SizedBox(height: 8),
                  ...fields.map((f) => _MetaLine(
                        icon: _iconForFieldKey(f.key),
                        label: f.label,
                        value: f.value,
                        onCopy: () => _copy(f.value),
                      )),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tags
          _ChipPanel(
            title: '标签',
            emptyText: '暂无',
            chips: d.tags,
          ),

          const SizedBox(height: 14),

          // Colors
          _ChipPanel(
            title: '颜色',
            emptyText: '暂无',
            chips: d.colors.map((e) => e.toUpperCase()).toList(),
          ),
        ],
      ),
    );
  }

  IconData _iconForFieldKey(String key) {
    final k = key.toLowerCase();
    if (k.contains('author') || k.contains('uploader') || k.contains('user')) return Icons.person_outline;
    if (k.contains('resolution') || k.contains('dimension')) return Icons.fullscreen;
    if (k.contains('ratio')) return Icons.crop_16_9;
    if (k.contains('file') && k.contains('type')) return Icons.insert_drive_file_outlined;
    if (k.contains('size')) return Icons.storage_outlined;
    if (k.contains('view')) return Icons.remove_red_eye_outlined;
    if (k.contains('fav') || k.contains('like')) return Icons.favorite_border;
    if (k.contains('short')) return Icons.link;
    if (k.contains('source') || k.contains('url')) return Icons.public;
    return Icons.info_outline;
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

class _HeaderLine extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _HeaderLine({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
            ),
          ),
        ],
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  final Color color;
  const _DividerLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color);
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _MetaLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

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
    final mono = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    Widget chip(String text) {
      return InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: text));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
        },
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