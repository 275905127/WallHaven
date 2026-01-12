// lib/pages/icon_wall_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IconWallPage extends StatefulWidget {
  const IconWallPage({super.key});

  @override
  State<IconWallPage> createState() => _IconWallPageState();
}

class _IconWallPageState extends State<IconWallPage> {
  final _searchCtrl = TextEditingController();
  String _q = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制：$text'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  List<_IconGroup> _filteredGroups() {
    final query = _q.trim().toLowerCase();
    if (query.isEmpty) return kIconGroups;

    final out = <_IconGroup>[];
    for (final g in kIconGroups) {
      final items = g.items
          .where((e) => e.name.toLowerCase().contains(query))
          .toList(growable: false);
      if (items.isNotEmpty) out.add(_IconGroup(g.title, items));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    final groups = _filteredGroups();
    final allItems = <_IconItem>[];
    for (final g in groups) {
      allItems.addAll(g.items);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('图标墙', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _q = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索 Icons.xxx（点图标复制）',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _q = "");
                        },
                      ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: allItems.isEmpty
                ? const Center(child: Text('没有匹配的图标'))
                : LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final crossAxisCount = w >= 900
                          ? 8
                          : w >= 700
                              ? 6
                              : w >= 520
                                  ? 5
                                  : 4;

                      return CustomScrollView(
                        slivers: [
                          for (final group in groups) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${group.items.length}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _IconTile(
                                    item: group.items[i],
                                    onCopy: _copy,
                                  ),
                                  childCount: group.items.length,
                                ),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.05,
                                ),
                              ),
                            ),
                          ],
                          const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final _IconItem item;
  final Future<void> Function(String) onCopy;

  const _IconTile({required this.item, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = 16.0;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: () => onCopy(item.name),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 28),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconGroup {
  final String title;
  final List<_IconItem> items;
  const _IconGroup(this.title, this.items);
}

class _IconItem {
  final String name;
  final IconData icon;
  const _IconItem(this.name, this.icon);
}

/// 你可以随时继续往这里加：name 一律写成 “Icons.xxx”
/// 点一下就会复制这串文本
const List<_IconGroup> kIconGroups = [
  _IconGroup("外观", [
    _IconItem("Icons.palette_outlined", Icons.palette_outlined),
    _IconItem("Icons.dark_mode_outlined", Icons.dark_mode_outlined),
    _IconItem("Icons.light_mode_outlined", Icons.light_mode_outlined),
    _IconItem("Icons.brightness_6_outlined", Icons.brightness_6_outlined),
    _IconItem("Icons.color_lens_outlined", Icons.color_lens_outlined),
    _IconItem("Icons.format_paint_outlined", Icons.format_paint_outlined),
    _IconItem("Icons.contrast_outlined", Icons.contrast_outlined),
    _IconItem("Icons.rounded_corner", Icons.rounded_corner),
    _IconItem("Icons.wallpaper_outlined", Icons.wallpaper_outlined),
    _IconItem("Icons.blur_on_outlined", Icons.blur_on_outlined),
  ]),
  _IconGroup("图源/网络", [
    _IconItem("Icons.hub", Icons.hub),
    _IconItem("Icons.source_outlined", Icons.source_outlined),
    _IconItem("Icons.public", Icons.public),
    _IconItem("Icons.link", Icons.link),
    _IconItem("Icons.cloud_outlined", Icons.cloud_outlined),
    _IconItem("Icons.cloud_download_outlined", Icons.cloud_download_outlined),
    _IconItem("Icons.cloud_upload_outlined", Icons.cloud_upload_outlined),
    _IconItem("Icons.cloud_sync_outlined", Icons.cloud_sync_outlined),
    _IconItem("Icons.wifi", Icons.wifi),
    _IconItem("Icons.http", Icons.http),
    _IconItem("Icons.key", Icons.key),
    _IconItem("Icons.filter_list", Icons.filter_list),
    _IconItem("Icons.tune", Icons.tune),
    _IconItem("Icons.search", Icons.search),
  ]),
  _IconGroup("备份/文件", [
    _IconItem("Icons.save_outlined", Icons.save_outlined),
    _IconItem("Icons.backup_outlined", Icons.backup_outlined),
    _IconItem("Icons.restore", Icons.restore),
    _IconItem("Icons.history", Icons.history),
    _IconItem("Icons.upload_file", Icons.upload_file),
    _IconItem("Icons.download", Icons.download),
    _IconItem("Icons.folder_open_outlined", Icons.folder_open_outlined),
    _IconItem("Icons.insert_drive_file_outlined", Icons.insert_drive_file_outlined),
    _IconItem("Icons.content_copy", Icons.content_copy),
    _IconItem("Icons.file_download_outlined", Icons.file_download_outlined),
    _IconItem("Icons.file_upload_outlined", Icons.file_upload_outlined),
    _IconItem("Icons.delete_outline", Icons.delete_outline),
    _IconItem("Icons.edit", Icons.edit),
    _IconItem("Icons.add", Icons.add),
  ]),
  _IconGroup("收藏/内容", [
    _IconItem("Icons.bookmark_outline", Icons.bookmark_outline),
    _IconItem("Icons.bookmark_add_outlined", Icons.bookmark_add_outlined),
    _IconItem("Icons.favorite_border", Icons.favorite_border),
    _IconItem("Icons.favorite", Icons.favorite),
    _IconItem("Icons.image_outlined", Icons.image_outlined),
    _IconItem("Icons.photo_outlined", Icons.photo_outlined),
    _IconItem("Icons.grid_view", Icons.grid_view),
    _IconItem("Icons.view_agenda_outlined", Icons.view_agenda_outlined),
  ]),
  _IconGroup("通用", [
    _IconItem("Icons.settings", Icons.settings),
    _IconItem("Icons.info_outline", Icons.info_outline),
    _IconItem("Icons.help_outline", Icons.help_outline),
    _IconItem("Icons.chevron_right", Icons.chevron_right),
    _IconItem("Icons.arrow_back", Icons.arrow_back),
    _IconItem("Icons.close", Icons.close),
    _IconItem("Icons.check", Icons.check),
    _IconItem("Icons.done", Icons.done),
    _IconItem("Icons.warning_amber_outlined", Icons.warning_amber_outlined),
  ]),
];