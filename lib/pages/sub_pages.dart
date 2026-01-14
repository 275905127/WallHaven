import 'package:flutter/material.dart';
import '../theme/theme_store.dart';
import '../widgets/foggy_app_bar.dart';
import '../widgets/settings_widgets.dart';

// ==========================================
// 1. 🎨 个性化设置页 (二级)
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

  @override
  Widget build(BuildContext context) {
    final store = ThemeScope.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FoggyAppBar(title: const Text("个性化"), isScrolled: _isScrolled, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        controller: _sc,
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
        children: [
          const SectionHeader(title: "界面风格"),
          SettingsGroup(items: [
             // 占位项
             SettingsItem(icon: Icons.color_lens, title: "自定义颜色", subtitle: "敬请期待", onTap: (){}),
          ]),
          
          const SizedBox(height: 24),
          const SectionHeader(title: "圆角设置"),
          // 这里我们直接用一个 Slider 来控制全局圆角，实现真正的"自定义"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(store.cornerRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("卡片圆角", style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    Text("${store.cornerRadius.toInt()} px", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ],
                ),
                Slider(
                  value: store.cornerRadius,
                  min: 4.0,
                  max: 32.0,
                  divisions: 28,
                  activeColor: store.accentColor,
                  onChanged: (val) {
                    store.setCornerRadius(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. 🖼️ 图源管理页 (二级)
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

  // 🌟 添加图源的中间弹窗
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
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "名称", hintText: "例如: My Server"),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: "API 地址", hintText: "https://..."),
            ),
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
          // 动态生成图源列表
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
            SettingsItem(
              icon: Icons.add_circle_outline, 
              title: "添加新图源", 
              onTap: () => _showAddSourceDialog(context),
            ),
          ]),
        ],
      ),
    );
  }
}
