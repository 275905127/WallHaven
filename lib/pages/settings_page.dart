import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 开关状态
  bool _welcomeSearch = false;
  bool _infoCatcher = false;
  bool _fixSearch = false;
  
  // 模拟存储的 API Key
  String _apiKey = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        
        slivers: [
          const SliverAppBar(
            pinned: true,
            floating: false,
            title: Text(
              "设置",
              style: TextStyle(
                color: Colors.black, 
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: false, 
            backgroundColor: Color(0xFFF2F2F2),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
          ),

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
                          // 【改动点】：把原来的开关改成了 API Key 输入入口
                          _buildApiKeyTile(),
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

  // 新增：构建 API Key 配置项
  Widget _buildApiKeyTile() {
    return InkWell(
      onTap: _showApiKeyDialog,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Wallhaven API Key", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    _apiKey.isEmpty ? "点击配置 API Key 以访问 NSFW 内容" : "已配置: ${_apiKey.substring(0, 4)}****", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 新增：显示输入弹窗
  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("设置 API Key"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "在此粘贴你的 API Key",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _apiKey = controller.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("API Key 已保存 (仅当前会话有效)")),
              );
            },
            child: const Text("保存"),
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
