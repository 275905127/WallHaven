import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 开关状态
  bool _quickSearchBar = true;
  bool _welcomeSearch = false;
  bool _infoCatcher = false;
  bool _fixSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      
      body: CustomScrollView(
        // 【关键点1】必须用 BouncingScrollPhysics 才能有下拉回弹的物理效果
        // AlwaysScrollableScrollPhysics 确保即使内容少也能下拉
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        
        slivers: [
          // 【关键点2】使用 SliverAppBar.large 实现大标题交互
          SliverAppBar.large(
            stretch: true, // 【核心】开启下拉拉伸效果（放大）
            pinned: true,  // 上滑时标题栏固定在顶部
            
            // 标题文本
            title: const Text("设置"),
            
            // 【关键点3】控制标题位置
            // centerTitle: false 表示标题平时靠左（在返回键旁边）
            // 如果你希望能“下拉时居中”，这是原生组件很难做到的动态动画，
            // 但开启 stretch 后，背景和文字的放大回弹会非常有质感。
            centerTitle: false, 

            // 颜色配置
            backgroundColor: const Color(0xFFF2F2F2),
            surfaceTintColor: Colors.transparent, // 滚动时不改变颜色
            
            // 展开高度，120-140 是比较舒适的大标题高度
            expandedHeight: 140.0,
            
            // 自动处理返回键颜色
            iconTheme: const IconThemeData(color: Colors.black),
          ),

          // 内容列表
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // 卡片 1：用户信息
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: _boxDecoration(),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("用户名", 
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.0)
                                ),
                                const SizedBox(height: 6),
                                const Text("Unknown", 
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF333333),
                            child: const Icon(Icons.person, size: 30, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 卡片 2：常规设置
                    Container(
                      decoration: _boxDecoration(),
                      child: Column(
                        children: [
                          _buildTile(title: "主题", subtitle: "设置应用主题"),
                          _divider(),
                          _buildTile(title: "语言", subtitle: "设置应用语言"),
                          _divider(),
                          SwitchListTile(
                            value: _quickSearchBar,
                            onChanged: (v) => setState(() => _quickSearchBar = v),
                            title: const Text("快速搜索栏", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text("在主屏幕上显示书签。", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            activeColor: Colors.white,
                            activeTrackColor: Colors.blue,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 卡片 3：书签管理
                    Container(
                      decoration: _boxDecoration(),
                      child: Column(
                        children: [
                          _buildTile(title: "书签顺序", subtitle: "排序书签"),
                          _divider(),
                          _buildTile(title: "重置书签", subtitle: "重置所有书签和类别。仅在出现错误时使用此功能。"),
                          _divider(),
                          _buildTile(title: "备份与恢复", subtitle: "备份和恢复 CheckFirm 书签和类别。"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 卡片 4：高级功能
                    Container(
                      decoration: _boxDecoration(),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            title: "欢迎搜索", 
                            subtitle: "启动时搜索固件。", 
                            value: _welcomeSearch, 
                            onChanged: (v) => setState(() => _welcomeSearch = v)
                          ),
                          _divider(),
                          _buildSwitchTile(
                            title: "信息捕获器", 
                            subtitle: "Info Catcher 将在固件更新时向您发送通知。", 
                            value: _infoCatcher, 
                            onChanged: (v) => setState(() => _infoCatcher = v)
                          ),
                          _divider(),
                          _buildSwitchTile(
                            title: "修复搜索错误", 
                            subtitle: "由于中国或伊朗等一些国家禁止使用Firebase，因此存在搜索错误。如果您在这些国家，请启用此设置。", 
                            value: _fixSearch, 
                            onChanged: (v) => setState(() => _fixSearch = v)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );
  }

  Widget _buildTile({required String title, required String subtitle}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title, 
    required String subtitle, 
    required bool value, 
    required Function(bool) onChanged
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)),
      activeColor: Colors.white,
      activeTrackColor: Colors.blue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0));
  }
}
