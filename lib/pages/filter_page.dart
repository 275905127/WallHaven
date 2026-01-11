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
        if (!_tempParams.containsKey(group.paramName)) {
          _tempParams[group.paramName] = currentFilters[group.paramName] ?? '';
        }
      }
    }
    
    // 初始化 Wallhaven 特有的 toplist 时间跨度
    if (!_tempParams.containsKey('topRange')) {
      _tempParams['topRange'] = currentFilters['topRange'] ?? '1M';
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
                   } else {
                     _tempParams[group.paramName] = '';
                   }
                }
                _tempParams['topRange'] = '1M';
              });
            },
            child: const Text("重置"),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final group = filters[index];
          return Column(
            children: [
              _buildFilterGroup(group),
              // 如果选了“榜单”，下方自动滑出“时间跨度”
              if (group.paramName == 'sorting' && _tempParams['sorting'] == 'toplist')
                _buildTopRangeSelector(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("应用筛选"),
        icon: const Icon(Icons.check),
        onPressed: _applyFilters,
      ),
    );
  }

  // 榜单专属时间跨度选择
  Widget _buildTopRangeSelector() {
    final ranges = {
      '1d': '1天', '3d': '3天', '1w': '1周', '1M': '1月', '3M': '3月', '6M': '6月', '1y': '1年'
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("榜单时间跨度", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ranges.entries.map((e) => ChoiceChip(
            label: Text(e.value),
            selected: _tempParams['topRange'] == e.key,
            onSelected: (val) => setState(() => _tempParams['topRange'] = e.key),
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterGroup(FilterGroup group) {
    final hasApiKey = context.read<AppState>().currentSource.apiKey.isNotEmpty;

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
              if (group.paramName == 'purity' && group.options[i].value == 'NSFW' && !hasApiKey)
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
        onSelected: (val) => setState(() => _tempBitmasks[group.paramName]![index] = val),
        checkmarkColor: _getChipColor(option.label, option.value, group.paramName),
        selectedColor: (_getChipColor(option.label, option.value, group.paramName) ?? Colors.blue).withOpacity(0.15),
      );
    } else {
      final isSelected = _tempParams[group.paramName] == option.value;
      return ChoiceChip(
        label: group.paramName == 'colors' && option.value != '' 
            ? Container(width: 20, height: 20, decoration: BoxDecoration(color: Color(int.parse("0xFF${option.value}")), shape: BoxShape.circle))
            : Text(option.label),
        selected: isSelected,
        onSelected: (val) => setState(() => _tempParams[group.paramName] = option.value),
      );
    }
  }

  void _applyFilters() {
    final appState = context.read<AppState>();
    _tempParams.forEach((key, value) => appState.updateParam(key, value));
    _tempBitmasks.forEach((key, boolList) {
      String mask = boolList.map((b) => b ? '1' : '0').join();
      appState.updateParam(key, mask);
    });
    appState.updateParam('page', 1);
    Navigator.pop(context);
  }

  Color? _getChipColor(String label, String value, String paramName) {
    if (paramName == 'purity') {
      if (value == 'SFW') return Colors.green;
      if (value == 'Sketchy') return Colors.orange;
      if (value == 'NSFW') return Colors.red;
    }
    if (paramName == 'categories') {
      if (value == 'General') return Colors.blue;
      if (value == 'Anime') return Colors.purple;
      if (value == 'People') return Colors.teal;
    }
    return Colors.blue;
  }
}
