import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models/source_config.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // 临时存储筛选状态，key = paramName, value = 实际值
  final Map<String, dynamic> _tempParams = {};
  
  // 专门用于 bitmask 类型的临时存储 (List<bool>)
  final Map<String, List<bool>> _tempBitmasks = {};

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final currentFilters = appState.activeParams;
    final sourceConfig = appState.currentSource;

    // 初始化临时状态
    // 1. 复制已有的简单参数
    _tempParams.addAll(currentFilters);

    // 2. 初始化 bitmask (比如 Wallhaven 的 categories: "100")
    for (var group in sourceConfig.filters) {
      if (group.type == 'bitmask') {
        String currentVal = currentFilters[group.paramName]?.toString() ?? "";
        // 如果没值，默认全选 (例如 "111")
        if (currentVal.length != group.options.length) {
          currentVal = "1" * group.options.length; 
        }
        
        // 转换成 bool 数组
        _tempBitmasks[group.paramName] = currentVal.split('').map((e) => e == '1').toList();
      } else if (group.type == 'radio') {
        // 如果是单选，确保有个默认值
        if (!_tempParams.containsKey(group.paramName) && group.options.isNotEmpty) {
          _tempParams[group.paramName] = group.options.first.value;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = context.read<AppState>().currentSource.filters;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("筛选"),
        actions: [
          TextButton(
            onPressed: () {
              // 重置逻辑：简单粗暴，清空所有
              setState(() {
                _tempParams.clear();
                for (var group in filters) {
                   if (group.type == 'bitmask') {
                     // 重置为全 1
                     _tempBitmasks[group.paramName] = List.filled(group.options.length, true);
                   } else if (group.options.isNotEmpty) {
                     _tempParams[group.paramName] = group.options.first.value;
                   }
                }
              });
            },
            child: const Text("重置"),
          )
        ],
      ),
      // 动态构建列表
      body: filters.isEmpty 
          ? const Center(child: Text("此图源没有配置筛选规则")) 
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final group = filters[index];
                return _buildFilterGroup(group);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("应用筛选"),
        icon: const Icon(Icons.check),
        onPressed: _applyFilters,
      ),
    );
  }

  // 核心：根据类型渲染不同的 UI 组件
  Widget _buildFilterGroup(FilterGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(group.options.length, (index) {
            final option = group.options[index];

            if (group.type == 'bitmask') {
              // === 渲染多选 Bitmask (Wallhaven 风格) ===
              final isSelected = _tempBitmasks[group.paramName]![index];
              return FilterChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    _tempBitmasks[group.paramName]![index] = val;
                  });
                },
                checkmarkColor: _getChipColor(option.label), // 保持一点点颜色逻辑
                selectedColor: (_getChipColor(option.label) ?? Colors.blue).withOpacity(0.15),
              );

            } else {
              // === 渲染单选 Radio ===
              final currentValue = _tempParams[group.paramName];
              final isSelected = currentValue == option.value;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _tempParams[group.paramName] = option.value;
                    });
                  }
                },
              );
            }
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _applyFilters() {
    final appState = context.read<AppState>();
    
    // 1. 应用普通参数
    _tempParams.forEach((key, value) {
      appState.updateParam(key, value);
    });

    // 2. 拼接并应用 Bitmask 参数
    _tempBitmasks.forEach((key, boolList) {
      // [true, false, true] -> "101"
      String mask = boolList.map((b) => b ? '1' : '0').join();
      appState.updateParam(key, mask);
    });
    
    // 重置页码
    appState.updateParam('page', 1);

    Navigator.pop(context);
  }

  // 辅助：给特定关键词加点颜色，好看一点
  Color? _getChipColor(String label) {
    if (label.contains('安全') || label.contains('SFW')) return Colors.green;
    if (label.contains('限制') || label.contains('NSFW')) return Colors.red;
    if (label.contains('擦边')) return Colors.orange;
    return Colors.blue;
  }
}
