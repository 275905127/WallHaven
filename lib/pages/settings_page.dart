import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models/source_config.dart'; // 引入图源配置模型

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取全局状态
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 动态计算卡片颜色 (保持之前的配色逻辑)
    // 浅色模式下使用 #FFFDFD (微暖白)
    final cardColor = isDark 
        ? (appState.useAmoled ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C)) 
        : const Color(0xFFFFFDFD);

    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text("设置", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      color: cardColor,
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
                      color: cardColor,
                      child: Column(
                        children: [
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "主题" : "Theme",
                            subtitle: _getThemeSubtitle(appState),
                            icon: Icons.palette_outlined,
                            textColor: textColor,
                            onTap: () => _showThemeDialog(context, appState),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "语言" : "Language",
                            subtitle: appState.locale.languageCode == 'zh' ? "简体中文" : "English",
                            icon: Icons.language,
                            textColor: textColor,
                            onTap: () => _showLanguageDialog(context, appState),
                          ),
                          _divider(),
                          // 图源管理入口
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "图源管理" : "Source Manager",
                            subtitle: appState.locale.languageCode == 'zh' ? "添加或切换第三方图源" : "Switch or add custom sources",
                            icon: Icons.source_outlined,
                            textColor: textColor,
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
    if (state.useMaterialYou) mode += " + 动态取色";
    if (state.useAmoled && state.themeMode != ThemeMode.light) mode += " (纯黑)";
    return mode;
  }

  // 1. 主题设置弹窗
  void _showThemeDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
      onSelected: (v) {
        if (v) state.setThemeMode(mode);
      },
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

  // 3. 图源列表弹窗
  void _showSourceDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
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
                subtitle: const Text("支持 Wallhaven, Pixabay 等任意 API"),
                onTap: () {
                  Navigator.pop(context); // 关闭列表
                  _showAddSourceDialog(context, state); // 打开添加弹窗
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. 添加图源弹窗 (支持自定义 API 和 JSON 映射)
  void _showAddSourceDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: "https://");
    
    // 默认预设为 Wallhaven 的结构，方便用户参考
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
                  TextField(
                    controller: nameCtrl, 
                    decoration: const InputDecoration(labelText: "名称 (例如: Pixabay)", hintText: "给图源起个名字")
                  ),
                  TextField(
                    controller: urlCtrl, 
                    decoration: const InputDecoration(labelText: "API 地址", hintText: "https://api.example.com/search")
                  ),
                  
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => showAdvanced = !showAdvanced),
                    child: Row(
                      children: [
                        Text(showAdvanced ? "收起高级解析配置" : "展开高级解析配置"),
                        Icon(showAdvanced ? Icons.expand_less : Icons.expand_more)
                      ],
                    ),
                  ),
                  
                  if (showAdvanced) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("JSON 字段映射", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: listKeyCtrl, 
                            decoration: const InputDecoration(labelText: "列表字段 (List Key)", hintText: "data", isDense: true)
                          ),
                          TextField(
                            controller: thumbKeyCtrl, 
                            decoration: const InputDecoration(labelText: "缩略图路径", hintText: "thumbs.large", isDense: true)
                          ),
                          TextField(
                            controller: fullKeyCtrl, 
                            decoration: const InputDecoration(labelText: "原图路径", hintText: "path", isDense: true)
                          ),
                          const SizedBox(height: 8),
                          const Text("提示：使用点号 . 访问嵌套对象", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
              TextButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                    // 创建配置
                    final config = SourceConfig(
                      name: nameCtrl.text,
                      baseUrl: urlCtrl.text,
                      listKey: listKeyCtrl.text.isEmpty ? 'data' : listKeyCtrl.text,
                      thumbKey: thumbKeyCtrl.text.isEmpty ? 'thumbs.large' : thumbKeyCtrl.text,
                      fullKey: fullKeyCtrl.text.isEmpty ? 'path' : fullKeyCtrl.text,
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

  Widget _buildCard({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _buildTile(BuildContext context, {
    required String title, required String subtitle, required IconData icon, required Color textColor,
    Widget? trailing, VoidCallback? onTap
  }) {
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
