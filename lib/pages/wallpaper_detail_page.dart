// ⚠️ 警示：详情页背景必须使用全局背景色（Theme scaffoldBackgroundColor），禁止手写彩色背景。
// ⚠️ 警示：整体只允许黑白灰；图标与信息展示保持克制，不要花里胡哨。

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/wallhaven_api.dart';
import '../models/wallpaper.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';

class WallpaperDetailPage extends StatefulWidget {
  final String id;

  /// 让进来就先有图，不等接口
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
  final ScrollController _sc = ScrollController();
  bool _isScrolled = false;

  WallpaperDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_sc.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);
    });
    _load();
  }

  Future<void> _load() async {
    final store = ThemeScope.of(context);
    final data = await WallhavenApi.getWallpaperDetail(
      baseUrl: store.currentSource.baseUrl,
      apiKey: store.currentSource.apiKey,
      id: widget.id,
    );
    if (!mounted) return;
    setState(() {
      _detail = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
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

  String _cnPurity(String? v) {
    switch (v) {
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
    switch (v) {
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
    final mono = _monoPrimary(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(
        title: const Text("详情"),
        isScrolled: _isScrolled,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_detail == null)
              ? Center(
                  child: Text(
                    "加载失败",
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                )
              : ListView(
                  controller: _sc,
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 96 + 10, 16, 24),
                  children: [
                    _previewCard(context),
                    const SizedBox(height: 14),
                    _infoCard(context),
                    const SizedBox(height: 14),
                    _tagsCard(context),
                  ],
                ),
    );
  }

  Widget _previewCard(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);
    final d = _detail!;
    final imageUrl = d.url.isNotEmpty ? d.url : (widget.heroThumb ?? '');

    final aspect = (d.width > 0 && d.height > 0) ? (d.width / d.height) : 16 / 9;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(store.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: aspect.clamp(0.5, 2.0),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (c, u) => Container(
            color: theme.cardColor,
            child: const Center(child: Icon(Icons.image, color: Colors.grey)),
          ),
          errorWidget: (c, u, e) => Container(
            color: theme.cardColor,
            child: const Center(child: Icon(Icons.error, color: Colors.grey)),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final d = _detail!;

    Widget row(String k, String v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(
                k,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(store.cardRadius),
        border: Border.all(color: mono.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "信息",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          row("分辨率", d.resolution ?? "${d.width}×${d.height}"),
          row("比例", d.ratio ?? "-"),
          row("分类", _cnCategory(d.category)),
          row("纯净度", _cnPurity(d.purity)),
          row("格式", d.fileType ?? "-"),
          row("大小", d.fileSize != null ? _humanSize(d.fileSize!) : "-"),
          row("浏览", d.views?.toString() ?? "-"),
          row("收藏", d.favorites?.toString() ?? "-"),
          row("作者", d.uploader ?? "-"),
          if ((d.shortUrl ?? '').isNotEmpty) row("短链", d.shortUrl!),
          if ((d.source ?? '').isNotEmpty) row("来源", d.source!),
        ],
      ),
    );
  }

  Widget _tagsCard(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final d = _detail!;

    final tags = d.tags;
    final colors = d.colors;

    Widget chip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: mono.withOpacity(theme.brightness == Brightness.dark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: mono.withOpacity(0.12)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          if (tags.isEmpty)
            Text("暂无标签", style: TextStyle(color: theme.textTheme.bodyMedium?.color))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map(chip).toList(),
            ),
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              "颜色（展示）",
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((c) => chip("#$c")).toList(),
            ),
          ],
        ],
      ),
    );
  }
}