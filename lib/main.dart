import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent, 
  ));
  runApp(const MyApp());
}

// ==========================================
// 1. 🎨 颜色配置
// ==========================================
class AppColors {
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF3F3F3);
  static const Color lightAlert = Color(0xFFE5E5E5);
  static const Color lightMenu = Color(0xFFEBEBEB);
  
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF414141);
  static const Color darkAlert = Color(0xFF1B1B1B);
  static const Color darkMenu = Color(0xFF333333);

  static const Color brandYellow = Color(0xFFD2AE00);
}

// ==========================================
// 2. 🚀 APP 主题配置
// ==========================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system; 
  Color _accentColor = Colors.blue; 
  String _accentName = "蓝色";

  void changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void changeAccent(Color color, String name) {
    setState(() {
      _accentColor = color;
      _accentName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      
      // === ☀️ 浅色主题 ===
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        dialogBackgroundColor: AppColors.lightAlert,
        dividerColor: AppColors.lightBackground,
        
        dialogTheme: const DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),
        
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.lightMenu,
          surfaceTintColor: Colors.transparent,
          textStyle: TextStyle(color: Colors.black, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),

        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, 
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark, 
              statusBarBrightness: Brightness.light,    
            ),
        ),
        
        // 🌟 开关样式 (浅色模式修正版)
        switchTheme: SwitchThemeData(
          // 滑块：开启白，关闭深灰
          thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : const Color(0xFF5D5D5D)),
          // 轨道：开启黑，关闭浅灰
          trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF0D0D0D) : const Color(0xFFE3E3E3)),
          
          // 🌟 重点修正：轨道边缘阴影/描边
          trackOutlineColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.transparent; // 开启时不需要描边
            }
            // 关闭时：给一个极淡的黑色描边 (10%透明度)，模拟边缘阴影/立体感
            return Colors.black.withOpacity(0.1); 
          }),
          // 描边宽度
          trackOutlineWidth: const MaterialStatePropertyAll(1.0),
        ),
        
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Color(0xFF8E8E93)),
        ),
      ),

      // === 🌙 深色主题 ===
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        dialogBackgroundColor: AppColors.darkAlert,
        dividerColor: AppColors.darkBackground,
        
        dialogTheme: const DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        ),

        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.darkMenu,
          surfaceTintColor: Colors.transparent,
          textStyle: TextStyle(color: Colors.white, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),

        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, 
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,      
            ),
        ),
        
        // 🌟 开关样式 (深色模式修正版)
        switchTheme: SwitchThemeData(
          // 滑块：开启黑，关闭浅灰
          thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF0D0D0D) : const Color(0xFFC4C4C4)),
          // 轨道：开启白，关闭深灰
          trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFFFFFFFF) : const Color(0xFF3B3B3B)),
          
          // 🌟 重点修正：轨道边缘阴影/描边
          trackOutlineColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.transparent; 
            }
            // 关闭时：给一个极淡的白色描边 (12%透明度)，让它在黑底上突显轮廓
            return Colors.white.withOpacity(0.12);
          }),
          trackOutlineWidth: const MaterialStatePropertyAll(1.0),
        ),
        
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      ),

      home: HomePage(
        currentMode: _themeMode,
        changeTheme: changeTheme,
        currentAccentName: _accentName,
        currentAccentColor: _accentColor,
        changeAccent: changeAccent,
      ),
    );
  }
}

// ... 下面的 HomePage, SettingsPage, 组件封装 保持完全不变 ...
// ... 为了节省你的复制时间，以下是直接复用的 SettingsPage 及其它组件 ...

// ==========================================
// 3. 🏠 首页
// ==========================================
class HomePage extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) changeTheme;
  final String currentAccentName;
  final Color currentAccentColor;
  final Function(Color, String) changeAccent;

  const HomePage({super.key, required this.currentMode, required this.changeTheme, required this.currentAccentName, required this.currentAccentColor, required this.changeAccent});

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    currentMode: currentMode,
                    onThemeChanged: changeTheme,
                    currentAccentName: currentAccentName,
                    currentAccentColor: currentAccentColor,
                    onAccentChanged: changeAccent,
                  ),
                ),
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
// 4. ⚙️ 设置页
// ==========================================
class SettingsPage extends StatefulWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onThemeChanged;
  final String currentAccentName;
  final Color currentAccentColor;
  final Function(Color, String) onAccentChanged;

  const SettingsPage({super.key, required this.currentMode, required this.onThemeChanged, required this.currentAccentName, required this.currentAccentColor, required this.onAccentChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _showLegacyModel = false;
  bool _hapticFeedback = true;

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

  void _showDynamicAccentMenu(BuildContext context) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isBottom = offset.dy > screenHeight * 0.6;
    
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx, 
      isBottom ? offset.dy - 10 : offset.dy + size.height + 10, 
      offset.dx + size.width, 
      isBottom ? offset.dy - 10 : offset.dy + size.height + 10,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              if (widget.currentAccentName == option["name"])
                Icon(Icons.check, size: 20, color: isDark ? Colors.white : Colors.black),
            ],
          ),
        );
      }).toList(),
    );

    if (result != null) {
      widget.onAccentChanged(result["color"], result["name"]);
    }
  }

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        ThemeMode tempMode = widget.currentMode;
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
                    widget.onThemeChanged(tempMode);
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
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      
      appBar: AppBar(
        centerTitle: true,
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _isScrolled ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor.withOpacity(0.95),
                theme.scaffoldBackgroundColor.withOpacity(0.95),
                theme.scaffoldBackgroundColor.withOpacity(0.0), 
              ],
              stops: const [0.0, 0.85, 1.0], 
            ) : null,
          ),
        ),
      ),
      
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 20),
        children: [
          const UserProfileHeader(),
          const SizedBox(height: 32),

          const SectionHeader(title: "我的 ChatGPT"),
          SettingsGroup(
            items: [
              SettingsItem(icon: Icons.person_outline, title: "个性化", onTap: () {}),
              SettingsItem(icon: Icons.grid_view, title: "应用", onTap: () {}),
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
          const SizedBox(height: 24),

          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.wb_sunny_outlined, 
                title: "外观", 
                subtitle: _getModeName(widget.currentMode), 
                onTap: () => _showAppearanceDialog(context)
              ),
              SettingsItem(
                icon: Icons.color_lens_outlined, 
                title: "重点色", 
                subtitle: widget.currentAccentName, 
                trailing: Builder(
                  builder: (innerContext) {
                    return GestureDetector(
                      onTap: () => _showDynamicAccentMenu(innerContext),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.currentAccentColor, shape: BoxShape.circle)),
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

          const SectionHeader(title: "常规"),
          SettingsGroup(
            items: [
              SettingsItem(
                icon: Icons.schema_outlined, 
                title: "显示传统模型",
                trailing: Switch(
                  value: _showLegacyModel, 
                  onChanged: (val) => setState(() => _showLegacyModel = val),
                ),
                onTap: () => setState(() => _showLegacyModel = !_showLegacyModel),
              ),
              SettingsItem(
                // 🌟 使用新图标
                icon: Icons.haptic_feedback, 
                title: "触觉反馈",
                trailing: Switch(
                  value: _hapticFeedback, 
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
                onTap: () => setState(() => _hapticFeedback = !_hapticFeedback),
              ),
              SettingsItem(
                icon: Icons.language, 
                title: "语言", 
                subtitle: "中文", 
                onTap: () {}
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
           const SectionHeader(title: "通知"),
           SettingsGroup(
             items: [
               SettingsItem(
                 icon: Icons.notifications_outlined,
                 title: "通知",
                 onTap: () {},
               ),
             ]
           ),
           const SizedBox(height: 200),
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

// ==========================================
// 5. 🧩 基础组件封装
// ==========================================

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

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  SettingsItem({required this.icon, required this.title, this.subtitle, this.trailing, required this.onTap});
}

class SettingsGroup extends StatelessWidget {
  final List<SettingsItem> items;
  static const double largeRadius = 16.0; 
  static const double smallRadius = 4.0;
  const SettingsGroup({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final bool isFirst = index == 0;
        final bool isLast = index == items.length - 1;
        final bool isSingle = items.length == 1;
        BorderRadius borderRadius;
        if (isSingle) borderRadius = BorderRadius.circular(largeRadius);
        else if (isFirst) borderRadius = const BorderRadius.only(topLeft: Radius.circular(largeRadius), topRight: Radius.circular(largeRadius), bottomLeft: Radius.circular(smallRadius), bottomRight: Radius.circular(smallRadius));
        else if (isLast) borderRadius = const BorderRadius.only(topLeft: Radius.circular(smallRadius), topRight: Radius.circular(smallRadius), bottomLeft: Radius.circular(largeRadius), bottomRight: Radius.circular(largeRadius));
        else borderRadius = BorderRadius.circular(smallRadius);

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(color: theme.cardColor, borderRadius: borderRadius),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: borderRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Icon(item.icon, color: theme.iconTheme.color, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                              if (item.subtitle != null) ...[const SizedBox(height: 2), Text(item.subtitle!, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color))],
                            ],
                          ),
                        ),
                        item.trailing ?? Icon(Icons.chevron_right, color: theme.brightness == Brightness.dark ? const Color(0xFF666666) : const Color(0xFFC7C7CC)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isLast) Container(height: 2, color: theme.dividerColor),
          ],
        );
      }),
    );
  }
}
