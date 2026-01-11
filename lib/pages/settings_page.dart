import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取全局状态
    final appState = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 动态计算容器颜色
    final cardColor = isDark 
        ? (appState.useAmoled ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C)) 
        : Colors.white;
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
                    // 用户信息卡片 (保持 UI 不变)
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

                    // 第一组：外观设置 (核心功能升级)
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
                            onTap: () => _showThemeDialog(context, appState), // 弹出高级主题设置
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
                          // 【改为图源设置入口】
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "图源管理" : "Image Sources",
                            subtitle: appState.locale.languageCode == 'zh' ? "切换或添加新的图片来源" : "Switch or add new sources",
                            icon: Icons.source_outlined,
                            textColor: textColor,
                            // 这里可以加一个 Switch 或 Chevron，保持风格
                            trailing: Icon(Icons.chevron_right, color: Colors.grey),
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

  // 1. 高级主题设置弹窗 (复刻参考图功能，保持 App 风格)
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
              
              // 深色模式 (单选)
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
              
              // 动态取色 (开关)
              SwitchListTile(
                title: const Text("动态取色 (Material You)"),
                value: state.useMaterialYou,
                onChanged: (v) => state.setMaterialYou(v),
                contentPadding: EdgeInsets.zero,
              ),
              
              // 纯黑背景 (开关)
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
        if (v) {
          state.setThemeMode(mode);
          // Navigator.pop(context); // 保持弹窗不关闭，方便继续设置
        }
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

  // 3. 图源管理弹窗
  void _showSourceDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
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
                  subtitle: Text(source.baseUrl),
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
                title: const Text("添加自定义 Wallhaven API"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddSourceDialog(context, state);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 添加图源弹窗
  void _showAddSourceDialog(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: "https://wallhaven.cc/api/v1/search");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("添加图源"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "名称 (例如: 赛博朋克风)")),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "API 地址")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                state.addSource(nameCtrl.text, urlCtrl.text);
                Navigator.pop(context);
              }
            }, 
            child: const Text("添加"),
          ),
        ],
      ),
    );
  }

  // UI 样式封装
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
