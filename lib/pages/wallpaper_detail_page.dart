// lib/pages/wallpaper_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/theme_store.dart';
import '../domain/entities/wallpaper_detail_item.dart';
import '../data/http/http_client.dart';
import '../data/source_factory.dart';
import '../data/repository/wallpaper_repository.dart';

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
      final store = ThemeScope.of(context);
      _repo.setSource(_factory.fromStore(store));

      final data = await _repo.detail(widget.id);
      if (!mounted) return;

      setState(() {
        _detail = data;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: true,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_detail == null)
                ? Center(
                    child: Text(
                      "加载失败",
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                  )
                : _body(context, _detail!),
      ),
    );
  }

  Widget _body(BuildContext context, WallpaperDetailItem d) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);

    final imageUrl = d.image.toString().isNotEmpty ? d.image.toString() : (widget.heroThumb ?? '');
    final aspect = (d.width > 0 && d.height > 0) ? (d.width / d.height) : 16 / 9;

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

          // meta card
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
                _actionsRow(context),
                const SizedBox(height: 10),

                // 通用：如果 domain 有就显示
                if ((d.author ?? '').trim().isNotEmpty) _metaLine(context, Icons.person_outline, "作者", d.author!),
                if (d.views != null) _metaLine(context, Icons.remove_red_eye_outlined, "浏览量", "${d.views}"),
                if (d.favorites != null) _metaLine(context, Icons.favorite_border, "收藏量", "${d.favorites}"),
                _metaLine(context, Icons.fullscreen, "分辨率", d.resolution ?? "${d.width}x${d.height}"),
                if (d.fileSize != null) _metaLine(context, Icons.insert_drive_file_outlined, "大小", _humanSize(d.fileSize!)),
                if ((d.fileType ?? '').trim().isNotEmpty) _metaLine(context, Icons.image_outlined, "格式", d.fileType!),
                if (d.shortUrl != null && d.shortUrl.toString().trim().isNotEmpty) _metaLine(context, Icons.link, "短链", d.shortUrl.toString()),
                if (d.sourceUrl != null && d.sourceUrl.toString().trim().isNotEmpty) _metaLine(context, Icons.public, "来源", d.sourceUrl.toString()),

                // ✅ 关键：fields 由 source 决定 label/value，UI 不理解语义
                for (final f in d.fields)
                  _metaLine(context, Icons.info_outline, f.label, f.value),
              ],
            ),
          ),

          const SizedBox(height: 14),
          _tagsPanel(context, d),
        ],
      ),
    );
  }

  Widget _actionsRow(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    Widget action(IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(icon, size: 22, color: theme.iconTheme.color ?? mono),
        ),
      );
    }

    return Row(
      children: [
        action(Icons.content_cut_outlined, () {}),
        const SizedBox(width: 6),
        action(Icons.share_outlined, () {}),
        const SizedBox(width: 6),
        action(Icons.file_download_outlined, () {}),
        const SizedBox(width: 6),
        action(Icons.bookmark_border, () {}),
        const Spacer(),
      ],
    );
  }

  Widget _metaLine(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: mono.withOpacity(0.55)),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
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
        ],
      ),
    );
  }

  Widget _tagsPanel(BuildContext context, WallpaperDetailItem d) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);
    final tags = d.tags;

    Widget chip(String text) {
      return Container(
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
            "标签",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            Text("暂无标签", style: TextStyle(color: theme.textTheme.bodyMedium?.color))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tags.map(chip).toList(),
            ),
        ],
      ),
    );
  }
}