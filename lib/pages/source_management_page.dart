// lib/pages/source_management_page.dart
import 'package:flutter/material.dart';

class SourceManagementPage extends StatefulWidget {
  const SourceManagementPage({super.key});

  @override
  State<SourceManagementPage> createState() => _SourceManagementPageState();
}

class _SourceManagementPageState extends State<SourceManagementPage> {
  // 假数据：先把 UI 结构跑通
  final List<_SourceItem> _items = [
    const _SourceItem(id: 'wallhaven', name: 'WallHaven', baseUrl: 'https://wallhaven.cc'),
    const _SourceItem(id: 'generic', name: 'Generic JSON', baseUrl: 'https://example.com/api'),
  ];

  String _currentId = 'wallhaven';

  void _pick(String id) {
    setState(() => _currentId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换：$id')),
    );
  }

  void _addFake() {
    setState(() {
      _items.add(
        _SourceItem(
          id: 'custom_${_items.length}',
          name: '自定义图源 ${_items.length - 1}',
          baseUrl: 'https://example.com/api/${_items.length}',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图源管理'),
        actions: [
          IconButton(
            onPressed: _addFake,
            icon: const Icon(Icons.add),
            tooltip: '添加（临时）',
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final it = _items[index];
          final isCurrent = it.id == _currentId;

          return ListTile(
            leading: Icon(isCurrent ? Icons.check_circle : Icons.link),
            title: Text(it.name),
            subtitle: Text(it.baseUrl),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                // 先占位：后面再接真正编辑
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('编辑：${it.name}（未实现）')),
                );
              },
            ),
            onTap: () => _pick(it.id),
          );
        },
      ),
    );
  }
}

class _SourceItem {
  final String id;
  final String name;
  final String baseUrl;

  const _SourceItem({
    required this.id,
    required this.name,
    required this.baseUrl,
  });
}