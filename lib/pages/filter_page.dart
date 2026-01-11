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
  final Map<String, dynamic> _tempParams = {};
  final Map<String, List<bool>> _tempBitmasks = {};

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final currentFilters = appState.activeParams;
    final sourceConfig = appState.currentSource;

    _tempParams.addAll(currentFilters);

    for (var group in sourceConfig.filters) {
      if (group.type == 'bitmask') {
        String currentVal = currentFilters[group.paramName]?.toString() ?? "";
        if (currentVal.length != group.options.length) {
          currentVal = "1" * group.options.length; 
        }
        _tempBitmasks[group.paramName] = currentVal.split('').map((e) => e == '1').toList();
      } else if (group.type == 'radio') {
        if (!_tempParams.containsKey(group.paramName) && group.options.isNotEmpty) {
           // 如果有默认值或已经是空，这里不强制赋值，或者根据需要赋默认值
           // _tempParams[group.paramName] = group.options.first.value;
        }
      }
    }
  }

  // === 核心逻辑：应用筛选 ===
  void _applyFilters() {
    final appState = context.read<AppState>();
    
    _tempParams.forEach((key, value) {
      appState.updateParam(key, value);
    });

    _tempBitmasks.forEach((key, boolList) {
      String mask = boolList.map((b) => b ? '1' : '0').join();
      appState.updateParam(key, mask);
    });
    
    appState.updateParam('page', 1);
  }

  @override
  Widget build(BuildContext context) {
    final filters = context.read<AppState>().currentSource.filters;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

    // 使用 PopScope 拦截返回事件
    return PopScope(
      canPop: false, // 禁止自动 Pop，我们需要先执行逻辑
      onPopInvoked: (didPop) {
        if (didPop) return;
        _applyFilters(); // 退出前应用筛选
        Navigator.pop(context); // 手动 Pop
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("筛选"),
          actions: [
            // === 修改：重置改为图标 ===
            IconButton(
              icon: Icon(Icons.restart_alt, color: textColor),
              tooltip: "重置",
              onPressed: () {
                setState(() {
                  _tempParams.clear();
                  for (var group in filters) {
                     if (group.type == 'bitmask') {
                       _tempBitmasks[group.paramName] = List.filled(group.options.length, true);
                     } else if (group.options.isNotEmpty) {
                       // 这里的逻辑看你是否需要重置回第一个，还是重置为空
                       // _tempParams[group.paramName] = group.options.first.value;
                     }
                  }
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
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
        // === 修改：移除 FloatingActionButton ===
      ),
    );
  }

  Widget _buildFilterGroup(FilterGroup group) {
    final appState = context.read<AppState>();
    final hasApiKey = appState.currentSource.apiKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < group.options.length; i++) ...[
              if (group.paramName == 'purity' && 
                  group.options[i].value == 'NSFW' && 
                  !hasApiKey) 
                  const SizedBox.shrink()
              else 
                  _buildOptionChip(group, i)
            ]
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOptionChip(FilterGroup group, int index) {
    final option = group.options[index];

    if (group.type == 'bitmask') {
      final isSelected = _tempBitmasks[group.paramName]![index];
      return FilterChip(
        label: Text(option.label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _tempBitmasks[group.paramName]![index] = val;
          });
        },
        checkmarkColor: _getChipColor(option.label),
        selectedColor: (_getChipColor(option.label) ?? Colors.blue).withOpacity(0.15),
      );
    } else {
      final currentValue = _tempParams[group.paramName];
      // 只要值相等就选中，处理空值的情况
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
  }

  Color? _getChipColor(String label) {
    if (label == 'SFW' || label == 'General') return Colors.green;
    if (label == 'NSFW') return Colors.red;
    if (label == 'Sketchy') return Colors.orange;
    if (label == 'Anime') return Colors.purpleAccent;
    if (label == 'People') return Colors.blueAccent;
    return Colors.blue;
  }
}
