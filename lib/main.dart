import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // 1. 沉浸式状态栏：强制透明，让内容能顶到最上面
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 状态栏背景透明
    systemNavigationBarColor: Colors.transparent, // 底部导航条透明
  ));
  runApp(const MyApp());
}

// ==========================================
// 1. 🎨 颜色配置中心 (附详细中文注释)
// ==========================================
class AppColors {
  // --- ☀️ 浅色模式颜色 ---
  static const Color lightBackground = Color(0xFFFFFFFF); // [浅色] 全局背景：纯白
  static const Color lightCard = Color(0xFFF3F3F3);       // [浅色] 卡片/按钮背景：浅灰
  static const Color lightAlert = Color(0xFFE5E5E5);      // [浅色] 弹窗背景：纯白 (ChatGPT原版弹窗通常是白的)
  static const Color lightMenu = Color(0xFFEBEBEB);       // [浅色] 重点色下拉菜单背景：浅灰
  static const Color lightDivider = Color(0xFFFFFFFF);    // [浅色] 分割线颜色

  // --- 🌙 深色模式颜色 ---
  static const Color darkBackground = Color(0xFF000000);  // [深色] 全局背景：纯黑
  static const Color darkCard = Color(0xFF414141);        // [深色] 卡片/按钮背景：深炭灰 (参考 ChatGPT 网页版)
  static const Color darkAlert = Color(0xFF1B1B1B);       // [深色] 弹窗背景：标准的深灰色 (你之前觉得发蓝是因为没用这个)
  static const Color darkMenu = Color(0xFF333333);        // [深色] 重点色下拉菜单背景
  static const Color darkDivider = Color(0xFF000000);     // [深色] 分割线颜色

  // --- 品牌色 ---
  static const Color brandYellow = Color(0xFFD2AE00);     // 头像底色：暗黄色
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

      // === ☀️ 浅色主题配置 ===
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground, // 页面背景：纯白
        cardColor: AppColors.lightCard,                     // 卡片背景：浅灰
        dialogBackgroundColor: AppColors.lightAlert,        // 弹窗背景：纯白
        dividerColor: AppColors.lightDivider,               // 分割线

        // 🌟 修复弹窗样式
        dialogTheme: const DialogTheme(
          backgroundColor: AppColors.lightAlert, // [浅色] 弹窗背景色
          surfaceTintColor: Colors.transparent,  // 🌟【关键】移除 M3 默认的蓝色/紫色滤镜
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))), // 圆角 18
        ),

        // 下拉菜单样式
        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.lightMenu,           // [浅色] 菜单背景
          surfaceTintColor: Colors.transparent, // 移除滤镜
          textStyle: TextStyle(color: Colors.black, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),

        // AppBar 基础样式
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent, // 移除滚动时的变色
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black), // 图标黑
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // 状态栏图标黑
          ),
        ),

        // 开关样式
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? Colors.white
                : const Color(0xFF5D5D5D),
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? const Color(0xFF0D0D0D)
                : const Color(0xFFE3E3E3),
          ),
          trackOutlineColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return Colors.transparent;
            return Colors.black.withOpacity(0.1); // [浅色] 关闭时的边缘描边：10%黑
          }),
          trackOutlineWidth: const MaterialStatePropertyAll(1.0),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Color(0xFF8E8E93)),
        ),
      ),

      // === 🌙 深色主题配置 ===
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCard,
        dialogBackgroundColor: AppColors.darkAlert,
        dividerColor: AppColors.darkDivider,

        dialogTheme: const DialogTheme(
          backgroundColor: AppColors.darkAlert,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),

        popupMenuTheme: const PopupMenuThemeData(
          color: AppColors.darkMenu,
          surfaceTintColor: Colors.transparent,
          textStyle: TextStyle(color: Colors.white, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),

        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? const Color(0xFF0D0D0D)
                : const Color(0xFFC4C4C4),
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? const Color(0xFFFFFFFF)
                : const Color(0xFF3B3B3B),
          ),
          trackOutlineColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return Colors.transparent;
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

// ==========================================
// 3. 🏠 首页
// ==========================================
class HomePage extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) changeTheme;
  final String currentAccentName;
  final Color currentAccentColor;
  final Function(Color, String) changeAccent;

  const HomePage({
    super.key,
    required this.currentMode,
    required this.changeTheme,
    required this.currentAccentName,
    required this.currentAccentColor,
    required this.changeAccent,
  });

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
// 4. ⚙️ 设置页 (包含所有动态逻辑)
// ==========================================
class SettingsPage extends StatefulWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onThemeChanged;
  final String currentAccentName;
  final Color currentAccentColor;
  final Function(Color, String) onAccentChanged;

  const SettingsPage({
    super.key,
    required this.currentMode,
    required this.onThemeChanged,
    required this.currentAccentName,
    required this.currentAccentColor,
    required this.onAccentChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScrollController _scrollController = ScrollController();

  // ✅ 用“雾化权重”替代 isScrolled：0~1，轻滚就有效
  double _fogT = 0.0;

  bool _showLegacyModel = false;
  bool _hapticFeedback = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // ✅ 更敏感：10~20px 就进入雾化区间
      final raw = (_scrollController.offset / 22.0).clamp(0.0, 1.0);
      // ✅ 非线性：前段更明显（更接近你参考图“空气压对比”的感觉）
      final t = Curves.easeOut.transform(raw);
      if ((t - _fogT).abs() > 0.01) setState(() => _fogT = t);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🟢 核心功能：智能避让菜单 (向上/向下弹)
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: option["isDefault"] == true ? Colors.grey[600] : option["color"],
                  shape: BoxShape.circle,
                ),
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
                  child: Text(
                    "确定",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

  // ✅ 标题栏“雾化/空气感”实现：不模糊，只用 wash + 超长渐变尾巴
  Widget _buildAeroHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final double status = MediaQuery.of(context).padding.top;
    // 标题栏 + 超长尾巴：尾巴负责“拖没分界”
    final double fogHeight = status + kToolbarHeight + 64;

    // wash 用黑/白去“压对比”，不是用背景色盖住
    final Color wash = isDark ? Colors.black : Colors.white;

    // ✅ t=0 也要有“底雾”，否则你会觉得“只有最顶部才有点意思”
    // 顶部更强：保护状态栏/标题可读；中段压对比；尾巴极软消边
    final double topA = lerpDouble(isDark ? 0.18 : 0.14, isDark ? 0.42 : 0.34, _fogT)!;
    final double midA = lerpDouble(isDark ? 0.10 : 0.07, isDark ? 0.22 : 0.16, _fogT)!;
    final double tailA = lerpDouble(isDark ? 0.035 : 0.025, isDark ? 0.09 : 0.07, _fogT)!;

    // ✅ 二段“空气层”用于消除残余分层感（非常轻）
    final double airA = lerpDouble(isDark ? 0.010 : 0.008, isDark ? 0.020 : 0.014, _fogT)!;

    return IgnorePointer(
      child: SizedBox(
        height: fogHeight,
        width: double.infinity,
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    wash.withOpacity(topA),
                    wash.withOpacity(midA),
                    wash.withOpacity(tailA),
                    Colors.transparent,
                  ],
                  // ✅ 非线性分布：中段停留更久，尾巴更长更软
                  stops: const [0.0, 0.52, 0.82, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            // 轻到几乎看不见，但能把“边界识别”打散
            ColoredBox(color: wash.withOpacity(airA)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

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

        // ✅ 只改这里：标题栏雾化
        flexibleSpace: _buildAeroHeader(context),
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
                onTap: () => _showAppearanceDialog(context),
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
                  },
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
                icon: Icons.vibration,
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
                onTap: () {},
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
            ],
          ),
          const SizedBox(height: 300),
        ],
      ),
    );
  }

  String _getModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return "系统 (默认)";
      case ThemeMode.light:
        return "浅色";
      case ThemeMode.dark:
        return "深色";
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