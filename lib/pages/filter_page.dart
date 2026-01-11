import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // 本地临时状态
  late Map<String, bool> _categories;
  late Map<String, bool> _purity;
  late String _selectedSort;
  late String _selectedTopRange;

  @override
  void initState() {
    super.initState();
    // 1. 从全局状态初始化 (回显上次的筛选)
    final filters = context.read<AppState>().activeFilters;
    
    // 解析 categories (例如 "100" -> General=true, others=false)
    String catStr = filters['categories'] ?? '111';
    _categories = {
      'General': catStr[0] == '1',
      'Anime': catStr[1] == '1',
      'People': catStr[2] == '1',
    };

    // 解析 purity
    String purStr = filters['purity'] ?? '100';
    _purity = {
      'SFW': purStr[0] == '1',
      'Sketchy': purStr[1] == '1',
      'NSFW': purStr[2] == '1',
    };

    _selectedSort = filters['sorting'] ?? 'date_added';
    _selectedTopRange = filters['topRange'] ?? '1M';
  }

  @override
  Widget build(BuildContext context) {
    // 映射 UI 显示文本
    final sortMap = {
      'date_added': '最新添加',
      'relevance': '相关度',
      'random': '随机',
      'views': '浏览量',
      'favorites': '收藏量',
      'toplist': '排行榜'
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("筛选"),
        actions: [
          TextButton(
            onPressed: () {
              // 重置逻辑
              setState(() {
                _categories = {'General': true, 'Anime': true, 'People': true};
                _purity = {'SFW': true, 'Sketchy': false, 'NSFW': false};
                _selectedSort = 'date_added';
              });
            },
            child: const Text("重置"),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 分类
          _buildSection("分类 (Categories)", [
            _buildFilterChip("常规", _categories['General']!, (v) => setState(() => _categories['General'] = v)),
            _buildFilterChip("动漫", _categories['Anime']!, (v) => setState(() => _categories['Anime'] = v)),
            _buildFilterChip("人物", _categories['People']!, (v) => setState(() => _categories['People'] = v)),
          ]),
          
          const SizedBox(height: 20),

          // 2. 分级
          _buildSection("分级 (Purity)", [
            _buildFilterChip("安全 (SFW)", _purity['SFW']!, (v) => setState(() => _purity['SFW'] = v), color: Colors.green),
            _buildFilterChip("擦边 (Sketchy)", _purity['Sketchy']!, (v) => setState(() => _purity['Sketchy'] = v), color: Colors.orange),
            _buildFilterChip("限制级 (NSFW)", _purity['NSFW']!, (v) => setState(() => _purity['NSFW'] = v), color: Colors.red),
          ]),

          const SizedBox(height: 20),

          // 3. 排序
          _buildSection("排序 (Sorting)", sortMap.entries.map((e) {
            return ChoiceChip(
              label: Text(e.value),
              selected: _selectedSort == e.key,
              onSelected: (v) => setState(() => _selectedSort = e.key),
            );
          }).toList()),

          // 4. 排行榜时间 (仅当选排行榜时显示)
          if (_selectedSort == 'toplist') ...[
            const SizedBox(height: 12),
            _buildSection("时间范围", ['1d', '3d', '1w', '1M', '3M', '6M', '1y'].map((e) {
               return ChoiceChip(
                label: Text(e),
                selected: _selectedTopRange == e,
                onSelected: (v) => setState(() => _selectedTopRange = e),
              );
            }).toList()),
          ]
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("应用筛选"),
        icon: const Icon(Icons.check),
        onPressed: () {
          // 1. 拼接 binary string
          String catStr = 
              "${_categories['General']! ? 1 : 0}${_categories['Anime']! ? 1 : 0}${_categories['People']! ? 1 : 0}";
          String purStr = 
              "${_purity['SFW']! ? 1 : 0}${_purity['Sketchy']! ? 1 : 0}${_purity['NSFW']! ? 1 : 0}";

          // 2. 更新全局状态
          context.read<AppState>().updateFilters({
            'categories': catStr,
            'purity': purStr,
            'sorting': _selectedSort,
            'topRange': _selectedTopRange,
          });

          // 3. 返回并刷新
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, Function(bool) onSelect, {Color? color}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelect,
      checkmarkColor: color,
      selectedColor: (color ?? Colors.blue).withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? (color ?? Colors.blue) : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
