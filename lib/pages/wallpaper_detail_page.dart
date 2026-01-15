import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/theme_store.dart';

// ✅ domain/data
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

  // ✅ 页面间共享 HttpClient（你不做全局 DI 的情况下，这是最省事且一致的做法）
  static final HttpClient _sharedHttp = HttpClient();

  SourceFactory? _factory;
  WallpaperRepository? _repo;

  String? _lastSourceConfigId;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final store = ThemeScope.of(context);
    final currentId = store.currentSourceConfig.id;

    // 第一次：创建 factory/repo，并加载
    if (!_bootstrapped) {
      _bootstrapped = true;

      _factory = SourceFactory(http: _sharedHttp);
      final src = _factory!.fromStore(store);
      _repo = WallpaperRepository(src);

      _lastSourceConfigId = currentId;
      _load();
      return;
    }

    // 切源：自动刷新详情
    if (_lastSourceConfigId != currentId) {
      _lastSourceConfigId = currentId;

      final src = _factory!.fromStore(store);
      _repo!.setSource(src);

      _reload();
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _detail = null;
    });
    await _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo!.detail(widget.id);
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

  String _cnRating(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'sfw':
        return '安全';
      case 'sketchy':
        return '擦边';
      case 'nsfw':
        return '限制';
      default:
        return '-';
    }
  }

  String _cnCategory(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'general':
        return '通用';
      case 'anime':
        return '动漫';
      case 'people':
        return '人物';
      default:
        return '-';
    }
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
                : _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);
    final d = _detail!;

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
                _metaLine(context, Icons.person_outline, "上传者", d.author ?? "-"),
                if (d.shortUrl != null && d.shortUrl.toString().isNotEmpty)
                  _metaLine(context, Icons.link, "短链", d.shortUrl.toString()),
                _metaLine(context, Icons.remove_red_eye_outlined, "浏览量", d.views?.toString() ?? "-"),
                _metaLine(context, Icons.favorite_border, "收藏量", d.favorites?.toString() ?? "-"),
                _metaLine(context, Icons.fullscreen, "分辨率", d.resolution ?? "${d.width}x${d.height}"),
                _metaLine(
                  context,
                  Icons.insert_drive_file_outlined,
                  "大小",
                  d.fileSize != null ? _humanSize(d.fileSize!) : "-",
                ),
                _metaLine(context, Icons.category_outlined, "分类", _cnCategory(d.category)),
                _metaLine(context, Icons.shield_outlined, "纯净度", _cnRating(d.rating)),
                _metaLine(context, Icons.image_outlined, "格式", d.fileType ?? "-"),
                if (d.sourceUrl != null && d.sourceUrl.toString().isNotEmpty)
                  _metaLine(context, Icons.public, "来源", d.sourceUrl.toString()),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _tagsPanel(context),
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

  Widget _tagsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);
    final d = _detail!;
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
            "相似搜索",
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