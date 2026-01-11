import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 模拟开关状态
  bool _quickSearchBar = true;
  bool _welcomeSearch = false;
  bool _infoCatcher = false;
  bool _fixSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景色与 main.dart 保持一致
      backgroundColor: const Color(0xFFF2F2F2),
      
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. 顶部大标题栏 (支持下拉放大)
          SliverAppBar.large(
            stretch: true, 
            centerTitle: false,
            title: const Text("设置", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFF2F2F2), // 必须与背景同色，否则下拉会露馅
            surfaceTintColor: Colors.transparent, 
            expandedHeight: 120,
            // 只有当不是首页跳转过来时，才需要手动写 leading，
            // 既然你是 push 进来的，系统自动生成的返回箭头是最标准的，不用改。
          ),

          // 2. 内容列表
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // ==============================
                    // 卡片 1：用户信息 (1:1 复刻)
                    // ==============================
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
                          // 深色头像
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF333333), // 参考图是深灰偏黑
                            child: const Icon(Icons.person, size: 30, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==============================
                    // 卡片 2：常规设置
                    // ==============================
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
                            // 【关键修改】：参考图是蓝色开关
                            activeColor: Colors.white,
                            activeTrackColor: Colors.blue, 
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            // 去掉左侧图标，保持简洁
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==============================
                    // 卡片 3：书签管理
                    // ==============================
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

                    // ==============================
                    // 卡片 4：高级功能 (开关组)
                    // ==============================
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
                    
                    // 底部加点留白
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

  // 样式：白色圆角卡片
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24), // 参考图圆角很大
      // 几乎不可见的阴影，保持扁平感
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );
  }

  // 组件：纯文字列表项 (无图标)
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
  
  // 组件：开关列表项
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

  // 组件：分割线
  Widget _divider() {
    // 缩进 20，颜色非常浅
    return const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0));
  }
}
