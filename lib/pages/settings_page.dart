import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../providers.dart';
import '../models/source_config.dart';
import 'favorites_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _kGithubRawUrlKey = 'cloud_github_raw_url_v1';
  static const _kWebDavFileUrlKey = 'cloud_webdav_file_url_v1';
  static const _kWebDavUserKey = 'cloud_webdav_user_v1';
  static const _kWebDavPassKey = 'cloud_webdav_pass_v1';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ChatGPT 标志性的背景色
    final Color backgroundColor = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("设置", 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.bold, 
            fontSize: 17
          )
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // === 1. 复刻版顶部个人资料区 ===
          _buildChatGPTProfileHeader(),

          // === 2. 当前状态分组 ===
          _buildSectionTitle("当前状态"),
          _buildGroupCard(context, [
            _buildTile(
              context,
              title: "当前图源",
              subtitle: appState.currentSource.name,
              icon: Icons.hub,
              trailing: Text(
                appState.currentSource.baseUrl.length > 20 
                  ? "${appState.currentSource.baseUrl.substring(0, 17)}..." 
                  : appState.currentSource.baseUrl,
                style: const TextStyle(fontSize: 11, color: Colors.grey)
              ),
              isLast: true,
            ),
          ]),

          // === 3. 个性化分组 ===
          _buildSectionTitle("个性化"),
          _buildGroupCard(context, [
            _buildTile(
              context,
              title: "外观设置",
              subtitle: "颜色模式、取色、圆角",
              icon: Icons.brightness_6_outlined,
              onTap: () => _showAppearanceSheet(context, appState),
            ),
            _buildTile(
              context,
              title: "我的收藏",
              subtitle: "查看已收藏的壁纸",
              icon: Icons.bookmark_outline,
              isLast: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
            ),
          ]),

          // === 4. 图源管理分组 ===
          _buildSectionTitle("数据管理"),
          _buildGroupCard(context, [
            _buildExpansionTile(
              context,
              title: "图源列表",
              subtitle: "管理已添加的 ${appState.sources.length} 个源",
              icon: Icons.source_outlined,
              children: [
                ...List.generate(appState.sources.length, (index) {
                  final s = appState.sources[index];
                  final isCurrent = appState.currentSource == s;
                  return _miniListTile(
                    context,
                    title: s.name,
                    subtitle: s.baseUrl,
                    leading: isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    leadingColor: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey,
                    onTap: () => appState.setSource(index),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showSourceConfigDialog(context, appState, existingSource: s, index: index),
                        ),
                        if (appState.sources.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                            onPressed: () => _confirmDelete(context, appState, index),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            _buildTile(
              context,
              title: "添加图源",
              subtitle: "自定义、JSON 或 URL 导入",
              icon: Icons.add_circle_outline,
              isLast: true,
              onTap: () => _showAddSourceOptions(context, appState),
            ),
          ]),

          // === 5. 备份与恢复 ===
          _buildSectionTitle("备份与恢复"),
          _buildGroupCard(context, [
            _buildTile(
              context,
              title: "云端配置",
              subtitle: "WebDAV / GitHub Raw 地址",
              icon: Icons.cloud_outlined,
              onTap: () => _showCloudConfigSheet(context),
            ),
            _buildTile(
              context,
              title: "同步与备份",
              subtitle: "本地 + 云端同步备份",
              icon: Icons.sync,
              onTap: () => _backupLocalAndMaybeCloud(context),
            ),
            _buildTile(
              context,
              title: "数据恢复",
              subtitle: "从云端、本地或上次备份恢复",
              icon: Icons.restore,
              isLast: true,
              onTap: () => _showRestoreOptions(context, appState),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ============================================================
  // UI 复刻组件
  // ============================================================

  Widget _buildChatGPTProfileHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFEBC412),
          child: Text("27", style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        const Text("星河 於长野", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("275905127", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: const Text("编辑个人资料", style: TextStyle(color: Colors.black87, fontSize: 13)),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(text.toUpperCase(), 
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.1)),
          ),
      ],
    );
  }

  Widget _buildExpansionTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        children: children,
      ),
    );
  }

  // ============================================================
  // 底部 Sheet 与对话框整合 (原逻辑函数)
  // ============================================================

  void _showAddSourceOptions(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit), 
              title: const Text("手动自定义图源"), 
              onTap: () { Navigator.pop(ctx); _showSourceConfigDialog(context, state); }
            ),
            ListTile(
              leading: const Icon(Icons.paste), 
              title: const Text("导入图源配置 (粘贴 JSON)"), 
              onTap: () { Navigator.pop(ctx); _showImportDialog(context, state); }
            ),
            ListTile(
              leading: const Icon(Icons.cloud_sync), 
              title: const Text("从云端导入 (URL)"), 
              onTap: () { Navigator.pop(ctx); _importSourceFromUrl(context); }
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreOptions(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_download), 
              title: const Text("从云端恢复"), 
              onTap: () { Navigator.pop(ctx); _restoreFromCloud(context); }
            ),
            ListTile(
              leading: const Icon(Icons.paste), 
              title: const Text("从本地恢复 (粘贴 JSON)"), 
              onTap: () { Navigator.pop(ctx); _importBackup(context); }
            ),
            ListTile(
              leading: const Icon(Icons.restore), 
              title: const Text("恢复到上次自动备份"), 
              onTap: () { Navigator.pop(ctx); _restoreLastBackup(context); }
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 外观设置（统一成一个 Sheet，排版规整）
  // ============================================================

  void _showAppearanceSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        ThemeMode tempMode = state.themeMode;
        bool tempMaterialYou = state.useMaterialYou;
        bool tempAmoled = state.useAmoled;
        double tempCardRadius = state.cornerRadius;
        double tempImgRadius = state.homeCornerRadius;

        return StatefulBuilder(builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final cardColor = state.customCardColor ?? theme.colorScheme.surface;
          final radius = state.cornerRadius;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text("外观设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      const Text("颜色模式", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _choiceChip(
                            ctx,
                            label: "跟随系统",
                            selected: tempMode == ThemeMode.system,
                            onTap: () => setState(() => tempMode = ThemeMode.system),
                          ),
                          _choiceChip(
                            ctx,
                            label: "浅色模式",
                            selected: tempMode == ThemeMode.light,
                            onTap: () => setState(() => tempMode = ThemeMode.light),
                          ),
                          _choiceChip(
                            ctx,
                            label: "深色模式",
                            selected: tempMode == ThemeMode.dark,
                            onTap: () => setState(() => tempMode = ThemeMode.dark),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      const Text("自定义颜色", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _switchRow(
                        ctx,
                        title: "动态取色",
                        value: tempMaterialYou,
                        onChanged: (v) => setState(() => tempMaterialYou = v),
                      ),
                      const SizedBox(height: 8),
                      _colorRow(
                        ctx,
                        title: "背景颜色",
                        color: state.customScaffoldColor,
                        onTap: () => _showHexColorPicker(ctx, "背景颜色", state.customScaffoldColor, (c) => state.setCustomScaffoldColor(c)),
                      ),
                      const SizedBox(height: 8),
                      _colorRow(
                        ctx,
                        title: "卡片颜色",
                        color: state.customCardColor,
                        onTap: () => _showHexColorPicker(ctx, "卡片颜色", state.customCardColor, (c) => state.setCustomCardColor(c)),
                      ),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      const Text("自定义圆角", style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      _sliderRow(
                        ctx,
                        label: "卡片圆角",
                        value: tempCardRadius,
                        min: 0,
                        max: 40,
                        onChanged: (v) => setState(() => tempCardRadius = v),
                      ),
                      const SizedBox(height: 6),
                      _sliderRow(
                        ctx,
                        label: "图片圆角",
                        value: tempImgRadius,
                        min: 0,
                        max: 40,
                        onChanged: (v) => setState(() => tempImgRadius = v),
                      ),

                      const SizedBox(height: 14),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 160),
                        child: tempMode == ThemeMode.light
                            ? const SizedBox.shrink()
                            : _switchRow(
                                ctx,
                                title: "纯黑背景（AMOLED）",
                                value: tempAmoled,
                                onChanged: (v) => setState(() => tempAmoled = v),
                              ),
                      ),

                      const SizedBox(height: 14),

                      FilledButton(
                        onPressed: () {
                          state.setThemeMode(tempMode);
                          state.setMaterialYou(tempMaterialYou);
                          state.setAmoled(tempAmoled);
                          state.setCornerRadius(tempCardRadius);
                          state.setHomeCornerRadius(tempImgRadius);
                          Navigator.pop(ctx);
                        },
                        child: const Text("保存"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // ============================================================
  // 备份与恢复：云端设置 / 备份 / 恢复
  // ============================================================

  Future<void> _showCloudConfigSheet(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final githubCtrl = TextEditingController(text: prefs.getString(_kGithubRawUrlKey) ?? "");
    final webdavCtrl = TextEditingController(text: prefs.getString(_kWebDavFileUrlKey) ?? "");
    final userCtrl = TextEditingController(text: prefs.getString(_kWebDavUserKey) ?? "");
    final passCtrl = TextEditingController(text: prefs.getString(_kWebDavPassKey) ?? "");

    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        final theme = Theme.of(ctx);
        final radius = context.read<AppState>().cornerRadius;
        final isDark = theme.brightness == Brightness.dark;
        final cardColor = context.read<AppState>().customCardColor ?? (isDark ? const Color(0xFF1C1C1E) : Colors.white);

        Future<void> save() async {
          await prefs.setString(_kGithubRawUrlKey, githubCtrl.text.trim());
          await prefs.setString(_kWebDavFileUrlKey, webdavCtrl.text.trim());
          await prefs.setString(_kWebDavUserKey, userCtrl.text.trim());
          await prefs.setString(_kWebDavPassKey, passCtrl.text);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Expanded(child: Text("云端配置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ]),
                    const SizedBox(height: 10),

                    _input(ctx, controller: githubCtrl, label: "GitHub Raw 地址（只读，用于恢复）", hint: "https://raw.githubusercontent.com/.../backup.json"),
                    const SizedBox(height: 10),
                    _input(ctx, controller: webdavCtrl, label: "WebDAV 文件 URL（用于备份/恢复）", hint: "https://dav.example.com/backup.json"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _input(ctx, controller: userCtrl, label: "WebDAV 用户名", hint: "")),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: passCtrl,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: "WebDAV 密码",
                              hintText: "",
                              isDense: true,
                              filled: true,
                              fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => obscure = !obscure),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.save_outlined),
                            label: const Text("保存"),
                            onPressed: () async {
                              await save();
                              if (ctx.mounted) Navigator.pop(ctx);
                              _toast(context, "✅ 已保存云端配置");
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text("测试 WebDAV"),
                            onPressed: () async {
                              await save();
                              final ok = await _testWebDav(ctx);
                              _toast(context, ok ? "✅ WebDAV 可用" : "❌ WebDAV 测试失败");
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _backupLocalAndMaybeCloud(BuildContext context) async {
    final state = context.read<AppState>();
    final prefs = await SharedPreferences.getInstance();

    final json = state.exportBackupJson();

    // 本地：复制到剪贴板（“本地可用”最稳）
    await Clipboard.setData(ClipboardData(text: json));

    // 云端：有 WebDAV 文件 URL 才上传
    final webdavUrl = (prefs.getString(_kWebDavFileUrlKey) ?? "").trim();
    final user = prefs.getString(_kWebDavUserKey) ?? "";
    final pass = prefs.getString(_kWebDavPassKey) ?? "";

    if (webdavUrl.isEmpty) {
      _toast(context, "✅ 已备份到本地（JSON 已复制）");
      return;
    }

    final ok = await _uploadToWebDav(webdavUrl, user, pass, json);
    _toast(context, ok ? "✅ 已备份：本地 + WebDAV" : "⚠️ 本地已备份（WebDAV 失败）");
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final githubUrl = (prefs.getString(_kGithubRawUrlKey) ?? "").trim();
    final webdavUrl = (prefs.getString(_kWebDavFileUrlKey) ?? "").trim();
    final user = prefs.getString(_kWebDavUserKey) ?? "";
    final pass = prefs.getString(_kWebDavPassKey) ?? "";

    // 规则：优先 GitHub Raw；否则 WebDAV
    if (githubUrl.isNotEmpty) {
      final ok = await context.read<AppState>().importBackupFromUrl(githubUrl);
      _toast(context, ok ? "✅ 已从 GitHub Raw 恢复" : "❌ GitHub Raw 恢复失败");
      return;
    }

    if (webdavUrl.isNotEmpty) {
      final json = await _downloadFromWebDav(webdavUrl, user, pass);
      if (json == null) {
        _toast(context, "❌ WebDAV 拉取失败");
        return;
      }
      final ok = await context.read<AppState>().importBackupJson(json);
      _toast(context, ok ? "✅ 已从 WebDAV 恢复" : "❌ WebDAV 恢复失败");
      return;
    }

    _toast(context, "先去配置 GitHub Raw 或 WebDAV");
  }

  // ============================================================
  // 现有：导入/恢复（保留本地粘贴 & 上次自动备份）
  // ============================================================

  void _importBackup(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("从本地粘贴备份 JSON"),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: ctrl,
            maxLines: 10,
            decoration: const InputDecoration(hintText: "把备份 JSON 粘贴进来…", border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<AppState>().importBackupJson(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _toast(context, ok ? "✅ 已恢复" : "❌ 导入失败");
            },
            child: const Text("恢复"),
          ),
        ],
      ),
    );
  }

  void _restoreLastBackup(BuildContext context) async {
    final state = context.read<AppState>();
    final last = state.getLastBackupJson();
    if (last == null || last.trim().isEmpty) {
      _toast(context, "没有找到上次自动备份");
      return;
    }
    final ok = await state.importBackupJson(last);
    _toast(context, ok ? "✅ 已恢复到上次自动备份" : "❌ 恢复失败");
  }

  // ============================================================
  // 图源管理：编辑 / 删除 / 导入 / 云端导入（URL）
  // ============================================================

  void _confirmDelete(BuildContext context, AppState state, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要删除这个图源吗？此操作无法撤销。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        final radius = state.cornerRadius;
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final cardColor = state.customCardColor ?? (isDark ? const Color(0xFF1C1C1E) : Colors.white);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(child: Text(isEditing ? "编辑图源" : "添加图源", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ]),
                    const SizedBox(height: 10),
                    _input(ctx, controller: nameCtrl, label: "名称", hint: "例如：Wallhaven"),
                    const SizedBox(height: 10),
                    _input(ctx, controller: urlCtrl, label: "API 地址", hint: "https://..."),
                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.filter_list),
                      label: Text("配置筛选规则（${tempFilters.length}）"),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        final result = await _openFilterEditor(ctx, List.from(tempFilters));
                        if (result != null) setState(() => tempFilters = result);
                      },
                    ),

                    const SizedBox(height: 10),
                    _input(ctx, controller: apiKeyCtrl, label: "API Key（可选）", hint: ""),

                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () => setState(() => showAdvanced = !showAdvanced),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("高级配置"),
                            const SizedBox(width: 4),
                            Icon(showAdvanced ? Icons.expand_less : Icons.expand_more),
                          ],
                        ),
                      ),
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 160),
                      child: showAdvanced
                          ? Column(
                              children: [
                                _input(ctx, controller: listKeyCtrl, label: "List Key", hint: "data"),
                                const SizedBox(height: 10),
                                _input(ctx, controller: thumbKeyCtrl, label: "Thumb Key", hint: "thumbs.large"),
                                const SizedBox(height: 10),
                                _input(ctx, controller: fullKeyCtrl, label: "Full Key", hint: "path"),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;

                        final newConfig = SourceConfig(
                          name: nameCtrl.text.trim(),
                          baseUrl: urlCtrl.text.trim(),
                          apiKey: apiKeyCtrl.text.trim(),
                          listKey: listKeyCtrl.text.trim(),
                          thumbKey: thumbKeyCtrl.text.trim(),
                          fullKey: fullKeyCtrl.text.trim(),
                          filters: tempFilters,
                        );

                        if (isEditing) {
                          state.updateSource(index!, newConfig);
                        } else {
                          state.addSource(newConfig);
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text("保存"),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showImportDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("导入图源配置"),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(hintText: "在此粘贴 SourceConfig JSON...", border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () {
              final ok = state.importSourceConfig(controller.text.trim());
              Navigator.pop(ctx);
              _toast(context, ok ? "✅ 导入成功" : "❌ 导入失败");
            },
            child: const Text("导入"),
          ),
        ],
      ),
    );
  }

  void _importSourceFromUrl(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("图源配置 URL"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "https://.../source.json")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<AppState>().importSourceFromUrl(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _toast(context, ok ? "✅ 图源已导入" : "❌ 导入失败");
            },
            child: const Text("导入"),
          ),
        ],
      ),
    );
  }

  Future<List<FilterGroup>?> _openFilterEditor(BuildContext context, List<FilterGroup> currentFilters) {
    return showDialog<List<FilterGroup>>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text("筛选规则编辑", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: currentFilters.isEmpty
                      ? const Center(child: Text("暂无筛选组", style: TextStyle(color: Colors.grey)))
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
                                title: Text(currentFilters[i].title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Text("参数：${currentFilters[i].paramName} ｜ 类型：${currentFilters[i].type}"),
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
                    onPressed: () async {
                      final newGroup = await _openGroupEditor(context, null);
                      if (newGroup != null) setState(() => currentFilters.add(newGroup));
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, currentFilters),
                    child: const Text("保存"),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.78),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(group == null ? "新建筛选组" : "编辑筛选组", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "显示标题（如：排序）", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: paramCtrl,
                    decoration: const InputDecoration(labelText: "API 参数名（如：sorting）", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: "类型", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'radio', child: Text("单选（Radio）")),
                      DropdownMenuItem(value: 'bitmask', child: Text("多选/位掩码（Bitmask）")),
                    ],
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  const Text("选项列表", style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...List.generate(options.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: options[index].label,
                              decoration: const InputDecoration(hintText: "名称", isDense: true, border: OutlineInputBorder()),
                              onChanged: (v) => options[index] = FilterOption(label: v, value: options[index].value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: options[index].value,
                              decoration: const InputDecoration(hintText: "值", isDense: true, border: OutlineInputBorder()),
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
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty || paramCtrl.text.trim().isEmpty) return;
                      Navigator.pop(
                        ctx,
                        FilterGroup(
                          title: titleCtrl.text.trim(),
                          paramName: paramCtrl.text.trim(),
                          type: type,
                          options: options,
                        ),
                      );
                    },
                    child: const Text("确认"),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // WebDAV：上传 / 下载 / 测试
  // ============================================================

  Future<bool> _testWebDav(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final url = (prefs.getString(_kWebDavFileUrlKey) ?? "").trim();
    if (url.isEmpty) return false;

    final user = prefs.getString(_kWebDavUserKey) ?? "";
    final pass = prefs.getString(_kWebDavPassKey) ?? "";

    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{...kAppHeaders};

      if (user.isNotEmpty || pass.isNotEmpty) {
        final basic = base64Encode(utf8.encode("$user:$pass"));
        headers["Authorization"] = "Basic $basic";
      }

      // HEAD 不一定支持，GET 更稳
      final resp = await http.get(uri, headers: headers);
      return resp.statusCode == 200 || resp.statusCode == 404; // 404 也算“连得上”
    } catch (_) {
      return false;
    }
  }

  Future<bool> _uploadToWebDav(String url, String user, String pass, String jsonString) async {
    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{
        ...kAppHeaders,
        "Content-Type": "application/json; charset=utf-8",
      };

      if (user.isNotEmpty || pass.isNotEmpty) {
        final basic = base64Encode(utf8.encode("$user:$pass"));
        headers["Authorization"] = "Basic $basic";
      }

      final resp = await http.put(uri, headers: headers, body: utf8.encode(jsonString));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _downloadFromWebDav(String url, String user, String pass) async {
    try {
      final uri = Uri.parse(url);
      final headers = <String, String>{...kAppHeaders};

      if (user.isNotEmpty || pass.isNotEmpty) {
        final basic = base64Encode(utf8.encode("$user:$pass"));
        headers["Authorization"] = "Basic $basic";
      }

      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 200) return null;
      return resp.body;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // UI 基建：统一的卡片 / tile / 折叠 / 输入
  // ============================================================

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.22 : 0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            _leadingIcon(theme, icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.55))),
              ]),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildExpansion(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        childrenPadding: EdgeInsets.zero,
        leading: _leadingIcon(theme, icon),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.55))),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: Colors.grey,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey)),
    );
  }

  Widget _subHeader(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800));
  }

  Widget _leadingIcon(ThemeData theme, IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 20, color: theme.colorScheme.primary),
    );
  }

  Widget _miniListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData leading,
    required Color leadingColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Icon(leading, size: 18, color: leadingColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.55))),
              ]),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _choiceChip(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withOpacity(0.14) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? theme.colorScheme.primary.withOpacity(0.35) : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color)),
      ),
    );
  }

  Widget _switchRow(BuildContext context, {required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _colorRow(BuildContext context, {required String title, required Color? color, required VoidCallback onTap}) {
    final show = color ?? Colors.grey[300]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            CircleAvatar(radius: 10, backgroundColor: show),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    const step = 0.5;
    double snap(double v) => (v / step).round() * step;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(snap(value).toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: onChanged,
            onChangeEnd: (v) => onChanged(snap(v)),
          ),
        ],
      ),
    );
  }

  TextField _input(BuildContext context, {required TextEditingController controller, required String label, required String hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
      ),
    );
  }

  String _modeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return "跟随系统";
      case ThemeMode.light:
        return "浅色模式";
      case ThemeMode.dark:
        return "深色模式";
    }
  }

  void _toast(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ============================================================
  // HEX 颜色输入（保留，但样式干净）
  // ============================================================

  void _showHexColorPicker(BuildContext context, String title, Color? currentColor, ValueChanged<Color?> onSelect) {
    final ctrl = TextEditingController();
    if (currentColor != null) {
      ctrl.text = currentColor.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("输入 HEX（$title）"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: "HEX",
            hintText: "AARRGGBB 或 RRGGBB",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onSelect(null);
              Navigator.pop(ctx);
            },
            child: const Text("恢复默认"),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          ElevatedButton(
            onPressed: () {
              try {
                String hex = ctrl.text.trim().replaceAll("#", "");
                if (hex.length == 6) hex = "FF$hex";
                if (hex.length == 8) {
                  final val = int.parse(hex, radix: 16);
                  onSelect(Color(val));
                  Navigator.pop(ctx);
                } else {
                  _toast(context, "格式错误：输入 6位 或 8位 HEX");
                }
              } catch (_) {
                _toast(context, "颜色解析失败");
              }
            },
            child: const Text("确定"),
          ),
        ],
      ),
    );
  }
}