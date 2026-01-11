import 'package:flutter/material.dart';

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
      // 保持背景色一致
      backgroundColor: const Color(0xFFF7F7F7),
      
      // 【关键修改】：使用 CustomScrollView 来支持高级滚动效果
      body: CustomScrollView(
        // 必须设置 BouncingScrollPhysics，否则在安卓上默认没有下拉回弹效果
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        
        slivers: [
          // 【核心组件】：支持下拉伸缩的大标题栏
          SliverAppBar.large(
            stretch: true, // 开启下拉放大效果！
            centerTitle: false, // 标题平时靠左
            title: const Text("设置"),
            
            // 系统会自动检测到你是从首页跳转过来的，因此会自动显示返回箭头
            // 如果你想强制显示，可以把下面这行解开，但通常不需要
            // automaticallyImplyLeading: true,

            backgroundColor: const Color(0xFFF7F7F7),
            surfaceTintColor: Colors.transparent, // 滚动时不改变颜色
            expandedHeight: 120, // 展开高度
          ),

          // 下面是原本的列表内容，现在需要用 SliverList 包裹
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
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
                    
                    // 底部留白，防止到底部太挤
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // 辅助样式方法（保持不变）
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
