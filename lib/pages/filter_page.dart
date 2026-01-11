import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';

class FilterPage extends StatelessWidget {
  const FilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filters = appState.currentSource.filters;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text("筛选"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                for (var group in filters) {
                  if (group.type == 'bitmask') {
                    appState.updateParam(group.paramName, "1" * group.options.length);
                  } else {
                    appState.updateParam(group.paramName, '');
                  }
                }
                appState.updateParam('topRange', '1M');
                appState.updateParam('page', 1);
              },
              child: const Text("重置"),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final group = filters[index];
          return _buildFilterSection(context, appState, group);
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, AppState state, dynamic group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(group.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF70757A))),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: group.options.asMap().entries.map<Widget>((entry) {
            final int idx = entry.key;
            final option = entry.value;
            
            bool isSelected = false;
            if (group.type == 'bitmask') {
              String mask = state.activeParams[group.paramName] ?? ("1" * group.options.length);
              isSelected = mask.length > idx && mask[idx] == '1';
            } else {
              isSelected = (state.activeParams[group.paramName] ?? '') == option.value;
            }

            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (val) {
                if (group.type == 'bitmask') {
                  String mask = state.activeParams[group.paramName] ?? ("1" * group.options.length);
                  List<String> chars = mask.split('');
                  chars[idx] = val ? '1' : '0';
                  state.updateParam(group.paramName, chars.join());
                } else {
                  state.updateParam(group.paramName, isSelected ? '' : option.value);
                }
                state.updateParam('page', 1);
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: Colors.blue.withOpacity(0.1),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isSelected ? Colors.blue : const Color(0xFFDADCE0)),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
