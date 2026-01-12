import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ChatGPT 经典的系统浅背景色
    const Color bgGray = Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgGray,
      appBar: AppBar(
        backgroundColor: bgGray,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "设置",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // === 1. 头像资料区 ===
          _buildProfileHeader(),

          const SizedBox(height: 10),

          // === 2. 我的 ChatGPT 分组 ===
          _buildSectionTitle("我的 ChatGPT"),
          _buildGroupCard([
            _buildTile(Icons.face_retouching_natural_outlined, "个性化"),
            _buildTile(Icons.widgets_outlined, "应用", isLast: true),
          ]),

          // === 3. 账户分组 ===
          _buildSectionTitle("账户"),
          _buildGroupCard([
            _buildTile(Icons.work_outline, "工作空间", trailingText: "个人"),
            _buildTile(Icons.auto_awesome_outlined, "升级至 Pro"),
            _buildTile(Icons.card_membership_outlined, "订阅", trailingText: "Plus"),
            _buildTile(Icons.mail_outline, "电子邮件", trailingText: "275905127@qq.com"),
            _buildTile(Icons.wb_sunny_outlined, "外观", trailingText: "系统", isLast: true),
          ]),

          // === 4. 其它分组 ===
          _buildSectionTitle("其它"),
          _buildGroupCard([
            _buildTile(Icons.help_outline, "帮助中心"),
            _buildTile(Icons.privacy_tip_outlined, "隐私政策"),
            _buildTile(Icons.info_outline, "关于", isLast: true),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 顶部头像组件
  Widget _buildProfileHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // 模仿截图中的黄色头像
        const CircleAvatar(
          radius: 38,
          backgroundColor: Color(0xFFEBC412),
          child: Text(
            "27",
            style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "星河 於长野",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 4),
        const Text(
          "275905127",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // 编辑资料按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text(
            "编辑个人资料",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // 分组标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
    );
  }

  // 白色圆角卡片容器
  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  // 通用的列表项
  Widget _buildTile(IconData icon, String title, {String? trailingText, bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: Icon(icon, color: Colors.black87, size: 22),
            title: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
              ],
            ),
            onTap: () {},
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 56), // 分割线避开图标
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade100),
          ),
      ],
    );
  }
}
