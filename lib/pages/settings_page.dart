import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models/source_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      body: CustomScrollView(
        // 【已删除】physics: const BouncingScrollPhysics(), 
        // 因为 main.dart 里的 scrollBehavior 会自动处理
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
                    // 当前图源卡片
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

                    // 设置项卡片
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
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "图源管理" : "Source Manager",
                            subtitle: appState.locale.languageCode == 'zh' ? "添加、切换或导入配置" : "Manage sources",
                            icon: Icons.source_outlined,
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _showSourceManagerDialog(context, appState),
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
    return mode;
  }

  // 1. 主题设置
  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        ThemeMode tempMode = state.themeMode;
        bool tempMaterialYou = state.useMaterialYou;
        bool tempAmoled = state.useAmoled;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("外观设置"),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("深色模式", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("跟随系统"),
                      value: ThemeMode.system,
                      groupValue: tempMode,
                      onChanged: (v) => setState(() => tempMode = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("浅色"),
                      value: ThemeMode.light,
                      groupValue: tempMode,
                      onChanged: (v) => setState(() => tempMode = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("深色"),
                      value: ThemeMode.dark,
                      groupValue: tempMode,
                      onChanged: (v) => setState(() => tempMode = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("动态取色 (Material You)"),
                      value: tempMaterialYou,
                      onChanged: (v) => setState(() => tempMaterialYou = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text("纯黑背景 (AMOLED)"),
                      subtitle: const Text("仅在深色模式下生效"),
                      value: tempAmoled,
                      onChanged: tempMode == ThemeMode.light ? null : (v) => setState(() => tempAmoled = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("取消", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    state.setThemeMode(tempMode);
                    state.setMaterialYou(tempMaterialYou);
                    state.setAmoled(tempAmoled);
                    Navigator.pop(context);
                  },
                  child: const Text("确定", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 2. 语言设置
  void _showLanguageDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = state.locale.languageCode;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("选择语言 / Language"),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text("简体中文"),
                    value: 'zh',
                    groupValue: tempLang,
                    onChanged: (v) => setState(() => tempLang = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text("English"),
                    value: 'en',
                    groupValue: tempLang,
                    onChanged: (v) => setState(() => tempLang = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.grey))),
                TextButton(
                  onPressed: () {
                    state.setLanguage(tempLang);
                    Navigator.pop(context);
                  },
                  child: const Text("确定", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 3. 图源管理
  void _showSourceManagerDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("图源管理"),
          contentPadding: const EdgeInsets.only(top: 20),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          content: SizedBox(
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
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
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
                    _showAddSourceDialog(context, state);
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
          actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text("关闭")),
          ],
        );
      },
    );
  }

  // 4. 导入配置
  void _showImportDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("导入配置"),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: "在此粘贴 JSON 配置代码...",
            filled: true,
            fillColor: Colors.black12,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              bool success = state.importSourceConfig(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? "导入成功！" : "导入失败，请检查 JSON 格式"),
                  backgroundColor: success ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }, 
            child: const Text("导入", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 5. 手动添加
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
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInput(nameCtrl, "名称 (Name)"),
                  const SizedBox(height: 10),
                  _buildInput(urlCtrl, "API 地址 (URL)"),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => showAdvanced = !showAdvanced),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(showAdvanced ? "收起高级配置" : "展开高级配置"), Icon(showAdvanced ? Icons.expand_less : Icons.expand_more)]
                    ),
                  ),
                  if (showAdvanced) ...[
                     _buildInput(listKeyCtrl, "List Key"),
                     const SizedBox(height: 8),
                     _buildInput(thumbKeyCtrl, "Thumb Key"),
                     const SizedBox(height: 8),
                     _buildInput(fullKeyCtrl, "Full Key"),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.grey))),
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
                child: const Text("添加", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: child));
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
