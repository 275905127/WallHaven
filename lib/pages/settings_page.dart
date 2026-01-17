class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('主题'),
            subtitle: Text('浅色 / 深色'),
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.filter_alt_outlined),
            title: Text('默认筛选'),
            subtitle: Text('分辨率 / 分类'),
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('版本信息'),
          ),
        ],
      ),
    );
  }
}