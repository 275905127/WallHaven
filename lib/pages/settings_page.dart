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
                            subtitle: appState.locale.languageCode == 'zh' ? "添加、编辑或删除" : "Manage sources",
                            icon: Icons.source_outlined,
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _showSourceManagerDialog(context),
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

  String _getThemeSubtitle(AppState state) {
    String mode = "跟随系统";
    if (state.themeMode == ThemeMode.light) mode = "浅色";
    if (state.themeMode == ThemeMode.dark) mode = "深色";
    return mode;
  }

  // --- 弹窗逻辑 ---

  // 1. 图源管理 (新增：删除功能 + Consumer 实时刷新)
  void _showSourceManagerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 使用 Consumer 确保列表数据变化时（比如删除了一个），弹窗内容会立即刷新
        return Consumer<AppState>(
          builder: (context, state, child) {
            return _buildBottomDialog(
              context,
              title: "图源管理",
              content: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
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
                        // 右侧操作栏：删除 + 编辑 + 选中状态
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // === 删除按钮 ===
                            // 只有当图源大于1个时才显示删除，防止删光
                            if (state.sources.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => _confirmDelete(context, state, index),
                              ),
                              
                            // === 编辑按钮 ===
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                              onPressed: () {
                                Navigator.pop(context); // 先关列表
                                _showSourceConfigDialog(context, state, existingSource: source, index: index);
                              },
                            ),
                            
                            // === 选中标记 ===
                            if (isSelected) 
                              const Icon(Icons.check_circle, color: Colors.blue),
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

  // 确认删除弹窗
  void _confirmDelete(BuildContext context, AppState state, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要删除这个图源吗？此操作无法撤销。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              state.removeSource(index); // 调用 Provider 的删除方法
              Navigator.pop(ctx);
            }, 
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 2. 添加/编辑图源
  void _showSourceConfigDialog(BuildContext context, AppState state, {SourceConfig? existingSource, int? index}) {
    final isEditing = existingSource != null;
    
    final nameCtrl = TextEditingController(text: existingSource?.name);
    final urlCtrl = TextEditingController(text: existingSource?.baseUrl ?? "https://");
    final apiKeyCtrl = TextEditingController(text: existingSource?.apiKey);
    
    final listKeyCtrl = TextEditingController(text: existingSource?.listKey ?? "data");
    final thumbKeyCtrl = TextEditingController(text: existingSource?.thumbKey ?? "thumbs.large");
    final fullKeyCtrl = TextEditingController(text: existingSource?.fullKey ?? "path");

    bool showAdvanced = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return _buildBottomDialog(
            context,
            title: isEditing ? "编辑图源" : "添加图源",
            confirmText: "保存",
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInput(nameCtrl, "名称 (Name)"),
                  const SizedBox(height: 10),
                  _buildInput(urlCtrl, "API 地址 (URL)"),
                  const SizedBox(height: 10),
                  _buildInput(apiKeyCtrl, "API Key (可选)"),
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
            onConfirm: () {
              if (nameCtrl.text.isNotEmpty) {
                final newConfig = SourceConfig(
                  name: nameCtrl.text,
                  baseUrl: urlCtrl.text,
                  apiKey: apiKeyCtrl.text,
                  listKey: listKeyCtrl.text,
                  thumbKey: thumbKeyCtrl.text,
                  fullKey: fullKeyCtrl.text,
                  filters: isEditing ? existingSource!.filters : [], 
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
        }
      ),
    );
  }

  // 3. 其他弹窗保持不变
  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        ThemeMode tempMode = state.themeMode;
        bool tempMaterialYou = state.useMaterialYou;
        bool tempAmoled = state.useAmoled;
        return StatefulBuilder(
          builder: (context, setState) => _buildBottomDialog(
            context, title: "外观设置",
            content: Column(children: [
              RadioListTile<ThemeMode>(title: const Text("跟随系统"), value: ThemeMode.system, groupValue: tempMode, onChanged: (v) => setState(() => tempMode = v!)),
              RadioListTile<ThemeMode>(title: const Text("浅色"), value: ThemeMode.light, groupValue: tempMode, onChanged: (v) => setState(() => tempMode = v!)),
              RadioListTile<ThemeMode>(title: const Text("深色"), value: ThemeMode.dark, groupValue: tempMode, onChanged: (v) => setState(() => tempMode = v!)),
              const Divider(),
              SwitchListTile(title: const Text("动态取色"), value: tempMaterialYou, onChanged: (v) => setState(() => tempMaterialYou = v)),
              SwitchListTile(title: const Text("纯黑背景"), value: tempAmoled, onChanged: tempMode == ThemeMode.light ? null : (v) => setState(() => tempAmoled = v)),
            ]),
            onConfirm: () { state.setThemeMode(tempMode); state.setMaterialYou(tempMaterialYou); state.setAmoled(tempAmoled); Navigator.pop(context); }
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = state.locale.languageCode;
        return StatefulBuilder(
          builder: (context, setState) => _buildBottomDialog(
            context, title: "选择语言",
            content: Column(children: [
              RadioListTile<String>(title: const Text("简体中文"), value: 'zh', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
              RadioListTile<String>(title: const Text("English"), value: 'en', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
            ]),
            onConfirm: () { state.setLanguage(tempLang); Navigator.pop(context); }
          ),
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => _buildBottomDialog(
      context, title: "导入配置",
      content: TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: "在此粘贴 JSON...")),
      confirmText: "导入",
      onConfirm: () {
        bool success = state.importSourceConfig(controller.text);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "导入成功" : "导入失败"), backgroundColor: success ? Colors.green : Colors.red));
      }
    ));
  }

  // --- 通用组件 ---

  Widget _buildBottomDialog(BuildContext context, {required String title, required Widget content, required VoidCallback onConfirm, String confirmText = "确定", bool hideCancel = false}) {
    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      shape: Theme.of(context).dialogTheme.shape,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          content,
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (!hideCancel) Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.grey, fontSize: 16)))),
            if (!hideCancel) const SizedBox(width: 16),
            Expanded(child: TextButton(onPressed: onConfirm, child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ]),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) { return Card(child: Padding(padding: const EdgeInsets.all(20), child: child)); }

  Widget _buildTile(BuildContext context, {required String title, required String subtitle, required IconData icon, Widget? trailing, VoidCallback? onTap}) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
        Icon(icon, color: textColor.withOpacity(0.7)), const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
        ])),
        if (trailing != null) trailing,
      ])),
    );
  }
  
  Widget _divider() => const Divider(height: 1, indent: 50, color: Color(0x10000000));
}
