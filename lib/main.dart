import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_store.dart';
import 'widgets/foggy_app_bar.dart';
import 'widgets/settings_widgets.dart';
import 'pages/sub_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 必须加，为了持久化
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, 
    systemNavigationBarColor: Colors.transparent, 
  ));
  
  final themeStore = ThemeStore();
  
  runApp(
    ThemeScope(
      store: themeStore,
      child: ListenableBuilder(
        listenable: themeStore,
        builder: (context, child) => const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: store.mode,
      theme: AppTheme.light(store.accentColor),
      darkTheme: AppTheme.dark(store.accentColor),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallhaven Pro"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text("当前源: ${store.currentSource.name}", style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ⚙️ 设置页 (主页)
// ==========================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _sc = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _sc.addListener(() {
      if (_sc.offset > 0 && !_isScrolled) setState(() => _isScrolled = true);
      else if (_sc.offset <= 0 && _isScrolled) setState(() => _isScrolled = false);
    });
  }

  // 主题弹窗
  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final store = ThemeScope.of(context);
        ThemeMode tempMode = store.mode;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("外观"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRadio(context, "系统 (默认)", ThemeMode.system, tempMode, (v) => setState(() => tempMode = v!)),
                  _buildRadio(context, "浅色", ThemeMode.light, tempMode, (v) => setState(() => tempMode = v!)),
                  _buildRadio(context, "深色", ThemeMode.dark, tempMode, (v) => setState(() => tempMode = v!)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () { store.setMode(tempMode); Navigator.pop(context); },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadio(BuildContext ctx, String title, ThemeMode val, ThemeMode group, ValueChanged<ThemeMode?> change) {
    return RadioListTile<ThemeMode>(
      title: Text(title), value: val, groupValue: group, onChanged: change,
      activeColor: Theme.of(ctx).colorScheme.primary, contentPadding: EdgeInsets.zero,
    );
  }

  // 重点色菜单
  void _showDynamicAccentMenu(BuildContext context) async {
    final store = ThemeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 简化的位置计算
    final result = await showMenu<Map<String, dynamic>>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0), // 简化处理
      color: isDark ? AppColors.darkMenu : AppColors.lightMenu,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        {"c": Colors.blue, "n": "蓝色"}, {"c": Colors.green, "n": "绿色"},
        {"c": Colors.orange, "n": "橙色"}, {"c": Colors.purple, "n": "紫色"},
      ].map((e) => PopupMenuItem(
        value: e,
        child: Row(
          children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: e['c'] as Color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(e['n'] as String),
          ],
        ),
      )).toList(),
    );

    if (result != null) {
      store.setAccent(result['c'], result['n']);
    }
  }

  // 切换图源弹窗
  void _showSourceSelectionDialog(BuildContext context) {
    final store = ThemeScope.of(context);
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("切换图源"),
        children: store.sources.map((source) {
          return SimpleDialogOption(
            onPressed: () { store.setSource(source); Navigator.pop(context); },
            child: Row(
              children: [
                Icon(source.isBuiltIn ? Icons.verified : Icons.link, color: theme.iconTheme.color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(source.name, style: const TextStyle(fontSize: 16))),
                if (store.currentSource.id == source.id) Icon(Icons.check, color: store.accentColor),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    final topPadding = MediaQuery.of(context).padding.top + 96;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(title: const Text('设置'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), isScrolled: _isScrolled),
      body: ListView(
        controller: _sc,
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
        children: [
          const UserProfileHeader(), // 头像组件
          const SizedBox(height: 32),
          
          const SectionHeader(title: "外观"),
          SettingsGroup(items: [
             SettingsItem(
               icon: Icons.person_outline, 
               title: "个性化", 
               subtitle: "自定义颜色与圆角",
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalizationPage())),
             ),
             SettingsItem(
               icon: Icons.wb_sunny_outlined, 
               title: "主题", 
               subtitle: store.mode.toString().split('.').last, // 简单显示
               onTap: () => _showAppearanceDialog(context)
             ),
             SettingsItem(
                icon: Icons.color_lens_outlined, 
                title: "重点色", 
                subtitle: store.accentName, 
                trailing: GestureDetector(
                  onTap: () => _showDynamicAccentMenu(context),
                  child: Container(width: 24, height: 24, decoration: BoxDecoration(color: store.accentColor, shape: BoxShape.circle)),
                ),
                onTap: () {}, 
              ),
          ]),
          
          const SizedBox(height: 24),
          const SectionHeader(title: "图源"),
          SettingsGroup(items: [
             SettingsItem(
               icon: Icons.swap_horiz, 
               title: "切换图源", 
               subtitle: store.currentSource.name,
               onTap: () => _showSourceSelectionDialog(context),
             ),
             SettingsItem(
               icon: Icons.settings_ethernet, 
               title: "图源管理", 
               subtitle: "添加或管理第三方源",
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SourceManagementPage())),
             ),
          ]),
          
          const SizedBox(height: 300),
        ],
      ),
    );
  }
}

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 80, height: 80, 
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
          child: Text("27", style: TextStyle(color: isDark ? Colors.white : Colors.black.withOpacity(0.7), fontSize: 32, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 16),
        Text("星河 於长野", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
