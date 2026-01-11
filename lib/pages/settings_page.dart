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
            iconTheme: IconThemeData(color: textColor),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildCard(context, child: _buildCurrentSourceInfo(appState, textColor)),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      child: Column(
                        children: [
                          _buildTile(context, title: "主题", subtitle: _getThemeSubtitle(appState), icon: Icons.palette_outlined, onTap: () => _showThemeDialog(context, appState)),
                          _divider(),
                          _buildTile(context, title: "语言", subtitle: appState.locale.languageCode == 'zh' ? "简体中文" : "English", icon: Icons.language, onTap: () => _showLanguageDialog(context, appState)),
                          _divider(),
                          _buildTile(context, title: "图源管理", subtitle: "切换、编辑或删除", icon: Icons.source_outlined, trailing: const Icon(Icons.chevron_right, color: Colors.grey), onTap: () => _showSourceManagerDialog(context)),
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

  Widget _buildBottomDialog(BuildContext context, {
    required String title,
    required Widget content,
    required VoidCallback onConfirm,
    String confirmText = "确定",
    bool hideCancel = false,
  }) {
    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                content,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F3F4)),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!hideCancel)
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        child: const Text("取消", style: TextStyle(color: Color(0xFF5F6368), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                if (!hideCancel)
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFF1F3F4), indent: 15, endIndent: 15),
                Expanded(
                  child: InkWell(
                    onTap: onConfirm,
                    borderRadius: hideCancel 
                        ? const BorderRadius.vertical(bottom: Radius.circular(32)) 
                        : const BorderRadius.only(bottomRight: Radius.circular(32)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Text(confirmText, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 其他方法逻辑省略，确保代码完整可运行 ---
  Widget _buildCurrentSourceInfo(AppState appState, Color textColor) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("当前图源", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        Text(appState.currentSource.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
      ])),
      CircleAvatar(radius: 26, backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.hub, color: Colors.blue)),
    ]);
  }

  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog(context: context, builder: (context) {
      ThemeMode tempMode = state.themeMode;
      return StatefulBuilder(builder: (context, setState) => _buildBottomDialog(
        context, title: "外观设置",
        content: Column(children: [
          RadioListTile(title: const Text("跟随系统"), value: ThemeMode.system, groupValue: tempMode, onChanged: (v) => setState(() => tempMode = v!)),
          RadioListTile(title: const Text("浅色"), value: ThemeMode.light, groupValue: tempMode, onChanged: (v) => setState(() => tempMode = v!)),
          RadioListTile(title: const Text("深色"), value: ThemeMode.dark, groupValue: tempMode, onChanged: (v) => setState(() => tempMode = v!)),
        ]),
        onConfirm: () { state.setThemeMode(tempMode); Navigator.pop(context); },
      ));
    });
  }

  void _showLanguageDialog(BuildContext context, AppState state) {
    showDialog(context: context, builder: (context) {
      String tempLang = state.locale.languageCode;
      return StatefulBuilder(builder: (context, setState) => _buildBottomDialog(
        context, title: "选择语言",
        content: Column(children: [
          RadioListTile(title: const Text("简体中文"), value: 'zh', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
          RadioListTile(title: const Text("English"), value: 'en', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
        ]),
        onConfirm: () { state.setLanguage(tempLang); Navigator.pop(context); },
      ));
    });
  }

  void _showSourceManagerDialog(BuildContext context) {
    final state = context.read<AppState>();
    showDialog(context: context, builder: (context) => _buildBottomDialog(
      context, title: "图源管理",
      content: const Text("这里可以自由切换 Wallhaven 或其他源"),
      onConfirm: () => Navigator.pop(context),
      confirmText: "关闭", hideCancel: true,
    ));
  }

  Widget _buildCard(BuildContext context, {required Widget child}) => Card(child: Padding(padding: const EdgeInsets.all(20), child: child));
  Widget _buildTile(BuildContext context, {required String title, required String subtitle, required IconData icon, Widget? trailing, VoidCallback? onTap}) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(16),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Icon(icon, color: Colors.black87), const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ])),
      if (trailing != null) trailing,
    ])),
  );
  Widget _divider() => const Divider(height: 1, color: Color(0x08000000));
  String _getThemeSubtitle(AppState state) => state.themeMode == ThemeMode.light ? "浅色" : (state.themeMode == ThemeMode.dark ? "深色" : "跟随系统");
}
