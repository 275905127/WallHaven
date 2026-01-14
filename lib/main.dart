import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 引入模块
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_store.dart'; // 引入状态仓库
import 'widgets/foggy_app_bar.dart';
import 'widgets/settings_widgets.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, 
    systemNavigationBarColor: Colors.transparent, 
  ));
  
  // 1. 在最顶层创建 Store
  final themeStore = ThemeStore();

  // 2. 注入 Scope，并使用 ListenableBuilder 监听变化
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

// ==========================================
// APP 入口
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. 直接从 Context 获取当前状态
    final store = ThemeScope.of(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: store.mode, // 动态绑定模式
      
      // 动态生成带颜色的主题
      theme: AppTheme.light(store.accentColor),
      darkTheme: AppTheme.dark(store.accentColor),

      home: const HomePage(), // 看！不需要传任何参数了！
    );
  }
}

// ==========================================
// 首页
// ==========================================
class HomePage extends StatelessWidget {
  const HomePage({super.key}); // 干净的构造函数

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChatGPT"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // 页面跳转也不需要传参了
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text("开始新的对话", style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ⚙️ 设置页
// ==========================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key}); // 干净的构造函数

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 重点色菜单
  void _showDynamicAccentMenu(BuildContext context) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size; 
    final Offset offset = renderBox.localToGlobal(Offset.zero); 
    final double screenHeight = MediaQuery.of(context).size.height; 
    const double estimatedMenuHeight = 360.0;
    final bool isBottom = (offset.dy + estimatedMenuHeight) > screenHeight;
    
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx, 
      isBottom ? offset.dy - estimatedMenuHeight : offset.dy + size.height + 10, 
      offset.dx + size.width, 
      isBottom ? offset.dy : 0, 
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 获取当前状态
    final store = ThemeScope.of(context);

    final List<Map<String, dynamic>> accentOptions = [
      {"color": Colors.grey, "name": "默认", "isDefault": true},
      {"color": Colors.blue, "name": "蓝色"},
      {"color": Colors.green, "name": "绿色"},
      {"color": Colors.yellow, "name": "黄色"},
      {"color": Colors.pink, "name": "粉色"},
      {"color": Colors.orange, "name": "橙色"},
      {"color": Colors.purple, "name": "紫色 · Plus"},
    ];

    final result = await showMenu<Map<String, dynamic>>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.darkMenu : AppColors.lightMenu, 
      elevation: 4,
      items: accentOptions.map((option) {
        return PopupMenuItem(
          value: option,
          height: 48,
          child: Row(
            children: [
              Container(
                width: 24, height: 24, 
                decoration: BoxDecoration(color: option["isDefault"] == true ? Colors.grey[600] : option["color"], shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(option["name"], style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
              const Spacer(),
              // 判断当前选中
              if (store.accentName == option["name"])
                Icon(Icons.check, size: 20, color: isDark ? Colors.white : Colors.black),
            ],
          ),
        );
      }).toList(),
    );

    if (result != null) {
      // 🌟 直接调用全局状态修改
      store.setAccent(result["color"], result["name"]);
    }
  }

  // 主题选择弹窗
  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        // 获取当前状态
        final store = ThemeScope.of(context);
        ThemeMode tempMode = store.mode;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 30), 
              title: const Text("外观", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
              content: SizedBox(
                width: MediaQuery.of(context).size.width, 
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRadioItem(context, "系统 (默认)", ThemeMode.system, tempMode, (val) => setState(() => tempMode = val!)),
                    _buildRadioItem(context, "浅色", ThemeMode.light, tempMode, (val) => setState(() => tempMode = val!)),
                    _buildRadioItem(context, "深色", ThemeMode.dark, tempMode, (val) => setState(() => tempMode = val!)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // 🌟 确认后提交修改
                    store.setMode(tempMode);
                    Navigator.pop(context);
                  },
                  child: Text("确定", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRadioItem(BuildContext context, String title, ThemeMode value, ThemeMode groupValue, ValueChanged<ThemeMode?> onChanged) {
    return RadioListTile<ThemeMode>(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + 96;
    // 获取当前状态用于显示
    final store = ThemeScope.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      
      appBar: FoggyAppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pop(context),
        ),
        isScrolled: _isScrolled,
      ),
      
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
        children: [
          const UserProfileHeader(),
          const SizedBox(height: 32),
          
          const SectionHeader(title: "外观"),
          SettingsGroup(
            items: [
              SettingsItem(icon: Icons.person_outline, title: "个性化", onTap: () {}),
              
              SettingsItem(
                icon: Icons.wb_sunny_outlined, 
                title: "主题", 
                subtitle: _getModeName(store.mode), // 读取状态
                onTap: () => _showAppearanceDialog(context)
              ),

              SettingsItem(
                icon: Icons.color_lens_outlined, 
                title: "重点色", 
                subtitle: store.accentName, // 读取状态
                trailing: Builder(
                  builder: (innerContext) {
                    return GestureDetector(
                      onTap: () => _showDynamicAccentMenu(innerContext),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: store.accentColor, shape: BoxShape.circle)), // 读取状态
                          const SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color!.withOpacity(0.5)), 
                        ],
                      ),
                    );
                  }
                ),
                onTap: () {}, 
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const SectionHeader(title: "账户"),
          SettingsGroup(
            items: [
              SettingsItem(icon: Icons.work_outline, title: "工作空间", subtitle: "个人", onTap: () {}),
              SettingsItem(icon: Icons.star_outline, title: "升级至 Pro", onTap: () {}),
              SettingsItem(icon: Icons.email_outlined, title: "电子邮件", subtitle: "275905127@qq.com", onTap: () {}),
            ],
          ),
          
          const SizedBox(height: 300),
        ],
      ),
    );
  }

  String _getModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return "系统 (默认)";
      case ThemeMode.light: return "浅色";
      case ThemeMode.dark: return "深色";
    }
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
        const SizedBox(height: 4),
        Text("275905127", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(20)),
          child: Text("编辑个人资料", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
