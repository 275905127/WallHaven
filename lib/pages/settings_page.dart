// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models/source_config.dart';
import 'favorites_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text("设置", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: textColor),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // === 1. 当前图源卡片 ===
                    _buildCard(
                      context,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(appState.locale.languageCode == 'zh' ? "当前图源" : "Current Source",
                                      style: const TextStyle(color: Colors.grey, fontSize: 13, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Text(appState.currentSource.name,
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(appState.currentSource.baseUrl,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, overflow: TextOverflow.ellipsis),
                                      maxLines: 1),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.hub, size: 32, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // === 2. 基础设置卡片 ===
                    _buildCard(
                      context,
                      child: Column(
                        children: [
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "主题与外观" : "Theme & Appearance",
                            subtitle: _getThemeSubtitle(appState),
                            icon: Icons.palette_outlined,
                            onTap: () => _showThemeDialog(context, appState),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "语言" : "Language",
                            subtitle: appState.locale.languageCode == 'zh' ? "简体中文" : "English",
                            icon: Icons.language,
                            onTap: () => _showLanguageDialog(context, appState),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "图源管理" : "Source Manager",
                            subtitle: appState.locale.languageCode == 'zh' ? "添加、编辑或删除" : "Manage sources",
                            icon: Icons.source_outlined,
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            onTap: () => _showSourceManagerDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // === 3. 我的收藏 ===
                    _buildCard(
                      context,
                      child: _buildTile(
                        context,
                        title: appState.locale.languageCode == 'zh' ? "我的收藏" : "My Favorites",
                        subtitle: appState.locale.languageCode == 'zh' ? "查看已收藏的壁纸" : "View favorite wallpapers",
                        icon: Icons.bookmark_outline,
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // === 4. ✅ 备份与恢复（全量：源 + 收藏 + 外观 + 每源筛选） ===
                    _buildCard(
                      context,
                      child: Column(
                        children: [
                          _buildTile(
                            context,
                            title: "导出备份",
                            subtitle: "复制一段 JSON（可保存到云端/备忘录）",
                            icon: Icons.upload_file,
                            onTap: () => _exportBackup(context),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: "导入备份",
                            subtitle: "粘贴 JSON 一键恢复（含外观）",
                            icon: Icons.download,
                            onTap: () => _importBackup(context),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: "恢复到上次自动备份",
                            subtitle: "从本机 SharedPreferences 里找 app_backup_v1",
                            icon: Icons.restore,
                            onTap: () => _restoreLastBackup(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ 备份 UI
  // ============================================================

  void _exportBackup(BuildContext context) async {
    final state = context.read<AppState>();
    final json = state.exportBackupJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ 备份已复制到剪贴板")),
      );
    }
  }

  void _importBackup(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("导入备份 JSON"),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: ctrl,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: "把备份 JSON 粘贴进来…",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
            ElevatedButton(
              onPressed: () async {
                final state = context.read<AppState>();
                final ok = await state.importBackupJson(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? "✅ 已恢复（含外观/图源/收藏）" : "❌ 导入失败：JSON 不对或缺字段"),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text("导入并恢复"),
            ),
          ],
        );
      },
    );
  }

  void _restoreLastBackup(BuildContext context) async {
    final state = context.read<AppState>();
    final last = state.getLastBackupJson();
    if (last == null || last.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("没有找到上次自动备份")),
      );
      return;
    }
    final ok = await state.importBackupJson(last);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? "✅ 已恢复到上次自动备份" : "❌ 恢复失败"),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // 原有逻辑（基本不动）
  // ============================================================

  String _getThemeSubtitle(AppState state) {
    String mode = "跟随系统";
    if (state.themeMode == ThemeMode.light) mode = "浅色";
    if (state.themeMode == ThemeMode.dark) mode = "深色";
    return mode;
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final appState = context.read<AppState>();
    final radius = appState.cornerRadius;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = appState.customCardColor ?? (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }

  Widget _buildTile(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      Widget? trailing,
      VoidCallback? onTap}) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Row(children: [
          Icon(icon, color: textColor.withOpacity(0.7), size: 26),
          const SizedBox(width: 20),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13)),
          ])),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 70, endIndent: 0, color: Color(0x0D000000));

  // --- 外观弹窗（原样保留） ---
  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        ThemeMode tempMode = state.themeMode;
        bool tempMaterialYou = state.useMaterialYou;
        bool tempAmoled = state.useAmoled;
        double tempGlobalRadius = state.cornerRadius;
        double tempHomeRadius = state.homeCornerRadius;

        return StatefulBuilder(
          builder: (context, setState) {
            final dynamicShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tempGlobalRadius),
            );

            return _buildBottomDialog(
              context,
              title: "外观设置",
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildThemeRadio(context, "跟随系统", ThemeMode.system, tempMode, (v) => setState(() => tempMode = v)),
                          _buildThemeRadio(context, "浅色", ThemeMode.light, tempMode, (v) => setState(() => tempMode = v)),
                          _buildThemeRadio(context, "深色", ThemeMode.dark, tempMode, (v) => setState(() => tempMode = v)),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    SwitchListTile(title: const Text("动态取色"), value: tempMaterialYou, shape: dynamicShape, onChanged: (v) => setState(() => tempMaterialYou = v)),
                    SwitchListTile(
                      title: const Text("纯黑背景 (AMOLED)"),
                      value: tempAmoled,
                      shape: dynamicShape,
                      onChanged: tempMode == ThemeMode.light ? null : (v) => setState(() => tempAmoled = v),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      title: const Text("自定义背景颜色"),
                      trailing: CircleAvatar(backgroundColor: state.customScaffoldColor ?? Colors.grey[300], radius: 12),
                      shape: dynamicShape,
                      onTap: () => _showHexColorPicker(context, "背景颜色", state.customScaffoldColor, (c) {
                        state.setCustomScaffoldColor(c);
                        Navigator.pop(context);
                      }),
                    ),
                    ListTile(
                      title: const Text("自定义卡片颜色"),
                      trailing: CircleAvatar(backgroundColor: state.customCardColor ?? Colors.grey[300], radius: 12),
                      shape: dynamicShape,
                      onTap: () => _showHexColorPicker(context, "卡片颜色", state.customCardColor, (c) {
                        state.setCustomCardColor(c);
                        Navigator.pop(context);
                      }),
                    ),
                    const Divider(height: 24),
                    const SizedBox(height: 8),
                    _buildFancySlider(context, label: "全局圆角", value: tempGlobalRadius, max: 40.0, onChanged: (v) => setState(() => tempGlobalRadius = v)),
                    const SizedBox(height: 12),
                    _buildFancySlider(context, label: "首页图片", value: tempHomeRadius, max: 40.0, onChanged: (v) => setState(() => tempHomeRadius = v)),
                  ],
                ),
              ),
              onConfirm: () {
                state.setThemeMode(tempMode);
                state.setMaterialYou(tempMaterialYou);
                state.setAmoled(tempAmoled);
                state.setCornerRadius(tempGlobalRadius);
                state.setHomeCornerRadius(tempHomeRadius);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showHexColorPicker(BuildContext context, String title, Color? currentColor, ValueChanged<Color?> onSelect) {
    final ctrl = TextEditingController();
    if (currentColor != null) {
      ctrl.text = currentColor.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("输入 HEX 颜色 ($title)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: "HEX (例如: FFFFFF)",
                hintText: "AARRGGBB 或 RRGGBB",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => onSelect(null), child: const Text("恢复默认")),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () {
              try {
                String hex = ctrl.text.trim().replaceAll("#", "");
                if (hex.length == 6) hex = "FF$hex";
                if (hex.length == 8) {
                  final val = int.parse(hex, radix: 16);
                  onSelect(Color(val));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("格式错误，请输入 6位 或 8位 HEX")));
                }
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("颜色解析失败")));
              }
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }

  // 图源管理/导入等（原样保留）
  void _showSourceManagerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, state, child) {
            return _buildBottomDialog(
              context,
              title: "图源管理",
              content: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...List.generate(state.sources.length, (index) {
                      final source = state.sources[index];
                      final isSelected = state.currentSource == source;
                      return ListTile(
                        title: Text(source.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(source.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.sources.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => _confirmDelete(context, state, index),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                              onPressed: () {
                                Navigator.pop(context);
                                _showSourceConfigDialog(context, state, existingSource: source, index: index);
                              },
                            ),
                            if (isSelected) Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.primary) else const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          state.setSource(index);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text("添加自定义图源"),
                      onTap: () {
                        Navigator.pop(context);
                        _showSourceConfigDialog(context, state);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text("导入配置"),
                      onTap: () {
                        Navigator.pop(context);
                        _showImportDialog(context, state);
                      },
                    ),
                  ],
                ),
              ),
              onConfirm: () => Navigator.pop(context),
              confirmText: "关闭",
              hideCancel: true,
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppState state, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要删除这个图源吗？此操作无法撤销。"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).textTheme.bodyLarge?.color),
              child: const Text("取消")),
          TextButton(
            onPressed: () {
              state.removeSource(index);
              Navigator.pop(ctx);
            },
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSourceConfigDialog(BuildContext context, AppState state, {SourceConfig? existingSource, int? index}) {
    final isEditing = existingSource != null;
    final nameCtrl = TextEditingController(text: existingSource?.name);
    final urlCtrl = TextEditingController(text: existingSource?.baseUrl ?? "https://");
    final apiKeyCtrl = TextEditingController(text: existingSource?.apiKey);
    final listKeyCtrl = TextEditingController(text: existingSource?.listKey ?? "data");
    final thumbKeyCtrl = TextEditingController(text: existingSource?.thumbKey ?? "thumbs.large");
    final fullKeyCtrl = TextEditingController(text: existingSource?.fullKey ?? "path");

    List<FilterGroup> tempFilters = existingSource?.filters.toList() ?? [];
    bool showAdvanced = false;
    final unifiedTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return _buildBottomDialog(
          context,
          title: isEditing ? "编辑图源" : "添加图源",
          confirmText: "保存",
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildInput(context, nameCtrl, "名称 (Name)"),
                const SizedBox(height: 10),
                _buildInput(context, urlCtrl, "API 地址 (URL)"),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: Text("配置筛选规则 (${tempFilters.length})"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () async {
                      final result = await _openFilterEditor(context, List.from(tempFilters));
                      if (result != null) setState(() => tempFilters = result);
                    },
                  ),
                ),
                _buildInput(context, apiKeyCtrl, "API Key (可选)"),
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => showAdvanced = !showAdvanced),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("高级配置", style: TextStyle(color: unifiedTextColor, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(showAdvanced ? Icons.expand_less : Icons.expand_more, color: unifiedTextColor)
                        ],
                      ),
                    ),
                  ),
                ),
                if (showAdvanced) ...[
                  _buildInput(context, listKeyCtrl, "List Key"),
                  const SizedBox(height: 10),
                  _buildInput(context, thumbKeyCtrl, "Thumb Key"),
                  const SizedBox(height: 10),
                  _buildInput(context, fullKeyCtrl, "Full Key"),
                ]
              ],
            ),
          ),
          onConfirm: () {
            if (nameCtrl.text.isNotEmpty) {
              final newConfig = SourceConfig(
                name: nameCtrl.text,
                baseUrl: urlCtrl.text,
                apiKey: apiKeyCtrl.text,
                listKey: listKeyCtrl.text,
                thumbKey: thumbKeyCtrl.text,
                fullKey: fullKeyCtrl.text,
                filters: tempFilters,
              );
              if (isEditing) {
                state.updateSource(index!, newConfig);
              } else {
                state.addSource(newConfig);
              }
              Navigator.pop(context);
            }
          },
        );
      }),
    );
  }

  Future<List<FilterGroup>?> _openFilterEditor(BuildContext context, List<FilterGroup> currentFilters) {
    return showDialog<List<FilterGroup>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return Dialog(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          shape: Theme.of(context).dialogTheme.shape,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("筛选规则编辑", style: Theme.of(context).textTheme.titleLarge),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: currentFilters.isEmpty
                      ? const Center(child: Text("暂无筛选组，请点击下方添加", style: TextStyle(color: Colors.grey)))
                      : ReorderableListView(
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) newIndex -= 1;
                              final item = currentFilters.removeAt(oldIndex);
                              currentFilters.insert(newIndex, item);
                            });
                          },
                          children: [
                            for (int i = 0; i < currentFilters.length; i++)
                              ListTile(
                                key: ValueKey(currentFilters[i]),
                                title: Text(currentFilters[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("参数: ${currentFilters[i].paramName} | 类型: ${currentFilters[i].type}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () async {
                                        final edited = await _openGroupEditor(context, currentFilters[i]);
                                        if (edited != null) setState(() => currentFilters[i] = edited);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => setState(() => currentFilters.removeAt(i)),
                                    ),
                                    const Icon(Icons.drag_handle, color: Colors.grey),
                                  ],
                                ),
                              )
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("添加筛选组"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final newGroup = await _openGroupEditor(context, null);
                      if (newGroup != null) setState(() => currentFilters.add(newGroup));
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(ctx, currentFilters),
                    child: const Text("保存全部规则"),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<FilterGroup?> _openGroupEditor(BuildContext context, FilterGroup? group) {
    final titleCtrl = TextEditingController(text: group?.title);
    final paramCtrl = TextEditingController(text: group?.paramName);
    String type = group?.type ?? 'radio';
    List<FilterOption> options = group?.options.toList() ?? [];

    return showDialog<FilterGroup>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return Dialog(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          shape: Theme.of(context).dialogTheme.shape,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(group == null ? "新建筛选组" : "编辑筛选组", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  _buildInput(context, titleCtrl, "显示标题 (如: 排序)"),
                  const SizedBox(height: 10),
                  _buildInput(context, paramCtrl, "API参数名 (如: sorting)"),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: "类型", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'radio', child: Text("单选 (Radio)")),
                      DropdownMenuItem(value: 'bitmask', child: Text("多选/位掩码 (Bitmask)")),
                    ],
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 20),
                  const Text("选项列表:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: options[index].label,
                              decoration: const InputDecoration(hintText: "名称", isDense: true, contentPadding: EdgeInsets.all(8)),
                              onChanged: (v) => options[index] = FilterOption(label: v, value: options[index].value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: options[index].value,
                              decoration: const InputDecoration(hintText: "值", isDense: true, contentPadding: EdgeInsets.all(8)),
                              onChanged: (v) => options[index] = FilterOption(label: options[index].label, value: v),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setState(() => options.removeAt(index)),
                          )
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("添加选项"),
                    onPressed: () => setState(() => options.add(FilterOption(label: "", value: ""))),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
                    onPressed: () {
                      if (titleCtrl.text.isNotEmpty && paramCtrl.text.isNotEmpty) {
                        Navigator.pop(
                          ctx,
                          FilterGroup(
                            title: titleCtrl.text,
                            paramName: paramCtrl.text,
                            type: type,
                            options: options,
                          ),
                        );
                      }
                    },
                    child: const Text("确认"),
                  )
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showLanguageDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = state.locale.languageCode;
        return StatefulBuilder(
          builder: (context, setState) => _buildBottomDialog(
            context,
            title: "选择语言",
            content: Column(children: [
              RadioListTile<String>(title: const Text("简体中文"), value: 'zh', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
              RadioListTile<String>(title: const Text("English"), value: 'en', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
            ]),
            onConfirm: () {
              state.setLanguage(tempLang);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _buildBottomDialog(
        context,
        title: "导入配置",
        content: TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: "在此粘贴 JSON...")),
        confirmText: "导入",
        onConfirm: () {
          bool success = state.importSourceConfig(controller.text);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? "导入成功" : "导入失败"), backgroundColor: success ? Colors.green : Colors.red),
          );
        },
      ),
    );
  }

  // === 通用弹窗/输入/slider（原样保留） ===
  Widget _buildBottomDialog(BuildContext context, {required String title, required Widget content, required VoidCallback onConfirm, String confirmText = "确定", bool hideCancel = false}) {
    final buttonColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      shape: Theme.of(context).dialogTheme.shape,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * (isKeyboardOpen ? 0.9 : 0.7)),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Flexible(child: content),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (!hideCancel)
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: buttonColor,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("取消"),
                ),
              ),
            if (!hideCancel) const SizedBox(width: 16),
            Expanded(
              child: TextButton(
                onPressed: onConfirm,
                style: TextButton.styleFrom(
                  foregroundColor: buttonColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                child: Text(confirmText),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildInput(BuildContext context, TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        filled: true,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildFancySlider(BuildContext context, {required String label, required double value, required double max, required ValueChanged<double> onChanged}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const double step = 0.5;
    final int divisions = (max / step).round();
    double snap(double v) => (v / step).round() * step;
    final double displayValue = snap(value);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(displayValue.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              trackShape: const RoundedRectSliderTrackShape(),
              activeTrackColor: primaryColor,
              inactiveTrackColor: primaryColor.withOpacity(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0, elevation: 4.0),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.3),
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: (v) => onChanged(snap(v)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeRadio(BuildContext context, String label, ThemeMode value, ThemeMode groupValue, ValueChanged<ThemeMode> onChanged) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<ThemeMode>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}