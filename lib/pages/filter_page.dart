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
          // 默认只选中第一个 (对于 Wallhaven 来说就是 SFW=1, Sketchy=0, NSFW=0 -> "100")
          // 之前是 "1" * length 全选，现在改保守一点，或者保持原样。
          // 既然改了 NSFW 逻辑，我们保持全选逻辑不变，只控制 UI 显隐
          currentVal = "1" * group.options.length; 
        }
        _tempBitmasks[group.paramName] = currentVal.split('').map((e) => e == '1').toList();
      } else if (group.type == 'radio') {
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
              setState(() {
                _tempParams.clear();
                for (var group in filters) {
                   if (group.type == 'bitmask') {
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

  Widget _buildFilterGroup(FilterGroup group) {
    final appState = context.read<AppState>();
    // 判断是否有 Key (用于控制 NSFW 显示)
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
              // === 核心逻辑：动态过滤 NSFW 选项 ===
              // 如果是 purity 组，且选项是 NSFW，且没有 Key -> 则不显示
              if (group.paramName == 'purity' && 
                  group.options[i].value == 'NSFW' && 
                  !hasApiKey) 
                  const SizedBox.shrink() // 隐藏
              else 
                  // 正常显示
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
    Navigator.pop(context);
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
