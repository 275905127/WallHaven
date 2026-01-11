import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models/source_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // 直接从全局 Theme 获取统一的颜色，无需手动计算！
    final cardColor = Theme.of(context).cardTheme.color;
    // 文本颜色根据背景自动适配
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text("设置", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: textColor),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // 卡片 1：当前图源信息
                    _buildCard(
                      context,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appState.locale.languageCode == 'zh' ? "当前图源" : "Current Source", 
                                  style: TextStyle(color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text(appState.currentSource.name, 
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                                const SizedBox(height: 4),
                                Text(appState.currentSource.baseUrl, 
                                  style: TextStyle(fontSize: 10, color: Colors.grey, overflow: TextOverflow.ellipsis), maxLines: 1),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.hub, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 卡片 2：外观与功能
                    _buildCard(
                      context,
                      child: Column(
                        children: [
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "主题" : "Theme",
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
                          // 图源管理入口
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "图源管理" : "Source Manager",
                            subtitle: appState.locale.languageCode == 'zh' ? "添加、切换或导入配置" : "Manage sources",
                            icon: Icons.source_outlined,
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _showSourceDialog(context, appState),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // --- 辅助方法 ---

  String _getThemeSubtitle(AppState state) {
    String mode = "跟随系统";
    if (state.themeMode == ThemeMode.light) mode = "浅色";
    if (state.themeMode == ThemeMode.dark) mode = "深色";
    if (state.useMaterialYou) mode += " + 动态";
    if (state.useAmoled && state.themeMode != ThemeMode.light) mode += " (AMOLED)";
    return mode;
  }

  // 1. 主题设置弹窗
  void _showThemeDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      // 样式已经在 main.dart 统一配置了，这里不需要再写
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("外观设置", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("深色模式", style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(context, state, "跟随系统", ThemeMode.system),
                  _buildThemeOption(context, state, "浅色", ThemeMode.light),
                  _buildThemeOption(context, state, "深色", ThemeMode.dark),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("动态取色 (Material You)"),
                value: state.useMaterialYou,
                onChanged: (v) => state.setMaterialYou(v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text("纯黑背景 (AMOLED)"),
                subtitle: const Text("仅在深色模式下生效"),
                value: state.useAmoled,
                onChanged: state.themeMode == ThemeMode.light ? null : (v) => state.setAmoled(v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, AppState state, String label, ThemeMode mode) {
    final isSelected = state.themeMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) { if (v) state.setThemeMode(mode); },
    );
  }

  // 2. 语言设置弹窗
  void _showLanguageDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("选择语言 / Language"),
        children: [
          SimpleDialogOption(
            onPressed: () { state.setLanguage('zh'); Navigator.pop(context); },
            child: const Padding(padding: EdgeInsets.all(12), child: Text("简体中文")),
          ),
          SimpleDialogOption(
            onPressed: () { state.setLanguage('en'); Navigator.pop(context); },
            child: const Padding(padding: EdgeInsets.all(12), child: Text("English")),
          ),
        ],
      ),
    );
  }

  // 3. 图源列表弹窗 (含导入功能)
  void _showSourceDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              // 顶部把手
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    const Text("选择图源", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...List.generate(state.sources.length, (index) {
                      final source = state.sources[index];
                      final isSelected = state.currentSource == source;
                      return ListTile(
                        title: Text(source.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(source.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          state.setSource(index);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const Divider(),
                    
                    // 手动添加
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text("添加自定义图源"),
                      subtitle: const Text("手动填写 API 和参数"),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _showAddSourceDialog(context, state);
                      },
                    ),
                    
                    // === 新增：导入配置 ===
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text("导入配置"),
                      subtitle: const Text("从剪贴板导入 JSON 配置"),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _showImportDialog(context, state);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. 导入配置弹窗
  void _showImportDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("导入配置"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "在此粘贴 JSON 配置代码...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              bool success = state.importSourceConfig(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? "导入成功！" : "导入失败，请检查 JSON 格式"),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }, 
            child: const Text("导入"),
          ),
        ],
      ),
    );
  }

  // 5. 手动添加弹窗 (保持逻辑不变，UI 自动适配)
  void _showAddSourceDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: "https://");
    final listKeyCtrl = TextEditingController(text: "data");
    final thumbKeyCtrl = TextEditingController(text: "thumbs.large");
    final fullKeyCtrl = TextEditingController(text: "path");
    
    bool showAdvanced = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("添加图源"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "名称")),
                  TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "API 地址")),
                  TextButton(
                    onPressed: () => setState(() => showAdvanced = !showAdvanced),
                    child: Row(children: [Text(showAdvanced ? "收起高级配置" : "展开高级配置"), Icon(showAdvanced ? Icons.expand_less : Icons.expand_more)]),
                  ),
                  if (showAdvanced) ...[
                     TextField(controller: listKeyCtrl, decoration: const InputDecoration(labelText: "List Key")),
                     TextField(controller: thumbKeyCtrl, decoration: const InputDecoration(labelText: "Thumb Key")),
                     TextField(controller: fullKeyCtrl, decoration: const InputDecoration(labelText: "Full Key")),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
              TextButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    final config = SourceConfig(
                      name: nameCtrl.text,
                      baseUrl: urlCtrl.text,
                      listKey: listKeyCtrl.text,
                      thumbKey: thumbKeyCtrl.text,
                      fullKey: fullKeyCtrl.text,
                    );
                    state.addSource(config);
                    Navigator.pop(context);
                  }
                }, 
                child: const Text("添加"),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- UI 组件封装 ---

  Widget _buildCard(BuildContext context, {required Widget child}) {
    // 颜色和形状由 main.dart 中的 CardTheme 统一接管，这里只需要结构
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  Widget _buildTile(BuildContext context, {
    required String title, required String subtitle, required IconData icon, 
    Widget? trailing, VoidCallback? onTap
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: textColor.withOpacity(0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 50, color: Color(0x10000000));
}
