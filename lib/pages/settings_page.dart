import 'package:flutter/material.dart';
import '../main.dart'; // 如果需要跳转回 main 或者用到全局配置

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _switchValue = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设置"),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          // 用户信息卡片
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: _boxDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("用户", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text("Wallhaven User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 32, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 第一组设置
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildTile(Icons.color_lens_outlined, "主题", "设置应用主题"),
                _divider(),
                _buildTile(Icons.language_outlined, "语言", "设置应用语言"),
                _divider(),
                SwitchListTile(
                  value: _switchValue,
                  onChanged: (v) => setState(() => _switchValue = v),
                  title: const Text("快速搜索栏", style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text("在主屏幕上显示书签", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  activeTrackColor: Colors.black,
                  activeColor: Colors.white,
                  secondary: const Icon(Icons.search),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 第二组设置
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildTile(Icons.sort, "书签顺序", "排序书签"),
                _divider(),
                _buildTile(Icons.restore, "重置书签", "重置所有书签和类别"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 5, offset: const Offset(0, 2)),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      onTap: () {},
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFEEEEEE));
  }
}
