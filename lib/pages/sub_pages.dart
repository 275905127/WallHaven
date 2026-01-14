import 'package:flutter/material.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';

// ==========================================
// 1. 🎨 个性化二级页
// ==========================================
class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
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

  void _showHexColorDialog(
    BuildContext context, 
    String title, 
    Color? currentColor, 
    Function(Color?) onColorChanged
  ) {
    String initHex = "";
    if (currentColor != null) {
      initHex = currentColor.value.toRadixString(16).toUpperCase().padLeft(8, '0').substring(2);
    }
    
    final TextEditingController textCtrl = TextEditingController(text: initHex);
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textCtrl,
                    decoration: InputDecoration(
                      labelText: "Hex 颜色代码",
                      hintText: "例如: FFFFFF",
                      prefixText: "# ",
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && val.length != 6) {
                        setState(() => errorText = "请输入 6 位颜色代码");
                      } else {
                        setState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text("预览: "),
                      const SizedBox(width: 8),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(textCtrl.text) ?? Colors.transparent,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    onColorChanged(null); 
                    Navigator.pop(context);
                  },
                  child: const Text("恢复默认", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    final color = _parseColor(textCtrl.text);
                    if (color != null) {
                      onColorChanged(color);
                      Navigator.pop(context);
                    } else {
                      setState(() => errorText = "无效的颜色代码");
                    }
                  },
                  child: const Text("确定"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color? _parseColor(String hex) {
    try {
      hex = hex.replaceAll("#", "");
      if (hex.length == 6) {
        hex = "FF$hex"; 
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }

  // 🛠️ 优化后的滑块组件：读写分离
  Widget _buildRadiusSlider(
    BuildContext context, 
    String title, 
    double value, 
    Function(double) onChanged, 
    VoidCallback onSave // 新增：保存回调
  ) {
    final theme = Theme.of(context);
    final store = ThemeScope.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(store.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
              Text("${value.toInt()} px", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
          Slider(
            value: value,
            min: 0.0, 
            max: 40.0, 
            divisions: 40,
            activeColor: store.accentColor,
            // 🌟 1. 拖动时：只更新内存，UI 极速响应
            onChanged: onChanged, 
            // 🌟 2. 松手时：才写入硬盘，防止卡顿
            onChangeEnd: (_) => onSave(), 
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    
    final bgHex = store.customBackgroundColor != null 
        ? "#${store.customBackgroundColor!.value.toRadixString(16).toUpperCase().substring(2)}" 
        : "默认";
    final cardHex = store.customCardColor != null 
        ? "#${store.customCardColor!.value.toRadixString(16).toUpperCase().substring(2)}" 
        : "默认";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(title: const Text("个性化"), isScrolled: _isScrolled, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        controller: _sc,
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
        children: [
          const SectionHeader(title: "界面风格"),
          SettingsGroup(items: [
             SettingsItem(
               icon: Icons.format_paint_outlined, 
               title: "全局背景颜色", 
               subtitle: bgHex,
               trailing: Container(
                 width: 24, height: 24,
                 decoration: BoxDecoration(
                   color: store.customBackgroundColor ?? Colors.transparent,
                   border: Border.all(color: Colors.grey.withOpacity(0.5)),
                   shape: BoxShape.circle,
                 ),
                 child: store.customBackgroundColor == null ? const Icon(Icons.auto_awesome, size: 14, color: Colors.grey) : null,
               ),
               onTap: () => _showHexColorDialog(context, "全局背景颜色", store.customBackgroundColor, (c) => store.setCustomBackgroundColor(c)),
             ),
             SettingsItem(
               icon: Icons.dashboard_customize_outlined, 
               title: "卡片颜色", 
               subtitle: cardHex,
               trailing: Container(
                 width: 24, height: 24,
                 decoration: BoxDecoration(
                   color: store.customCardColor ?? Colors.transparent,
                   border: Border.all(color: Colors.grey.withOpacity(0.5)),
                   shape: BoxShape.circle,
                 ),
                 child: store.customCardColor == null ? const Icon(Icons.auto_awesome, size: 14, color: Colors.grey) : null,
               ),
               onTap: () => _showHexColorDialog(context, "卡片颜色", store.customCardColor, (c) => store.setCustomCardColor(c)),
             ),
          ]),
          
          const SizedBox(height: 24),
          const SectionHeader(title: "圆角设置"),
          
          _buildRadiusSlider(
            context, 
            "卡片圆角", 
            store.cardRadius, 
            (val) => store.setCardRadius(val),
            () => store.savePreferences(), // 传入保存回调
          ),
          
          const SizedBox(height: 12),
          
          _buildRadiusSlider(
            context, 
            "首页图片圆角", 
            store.imageRadius, 
            (val) => store.setImageRadius(val),
            () => store.savePreferences(), // 传入保存回调
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. 图源管理二级页
// ==========================================
class SourceManagementPage extends StatefulWidget {
  const SourceManagementPage({super.key});
  @override
  State<SourceManagementPage> createState() => _SourceManagementPageState();
}

class _SourceManagementPageState extends State<SourceManagementPage> {
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

  void _showAddSourceDialog(BuildContext context) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController urlCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("添加图源"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "名称", hintText: "例如: My Server"), autofocus: true),
            const SizedBox(height: 16),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: "API 地址", hintText: "https://...")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                ThemeScope.of(context).addSource(nameCtrl.text, urlCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("添加"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(title: const Text("图源管理"), isScrolled: _isScrolled, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        controller: _sc,
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
        children: [
          const SectionHeader(title: "已添加的图源"),
          SettingsGroup(
            items: store.sources.map((source) {
              return SettingsItem(
                icon: source.isBuiltIn ? Icons.verified : Icons.link,
                title: source.name,
                subtitle: source.baseUrl,
                trailing: source.isBuiltIn 
                  ? const Text("内置", style: TextStyle(fontSize: 12, color: Colors.grey))
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => store.removeSource(source.id),
                    ),
                onTap: () {},
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SettingsGroup(items: [
            SettingsItem(icon: Icons.add_circle_outline, title: "添加新图源", onTap: () => _showAddSourceDialog(context)),
          ]),
        ],
      ),
    );
  }
}
