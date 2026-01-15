// lib/pages/filter_drawer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_store.dart';
import '../domain/entities/filter_spec.dart';
import '../domain/entities/source_capabilities.dart';
import '../domain/entities/option_item.dart';

class FilterDrawer extends StatefulWidget {
  final FilterSpec initial;
  final ValueChanged<FilterSpec> onApply;
  final VoidCallback onReset;
  final VoidCallback? onOpenSettings;

  const FilterDrawer({
    super.key,
    required this.initial,
    required this.onApply,
    required this.onReset,
    this.onOpenSettings,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late FilterSpec _f;
  late TextEditingController _qCtrl;
  Timer? _qDebounce;

  bool _expandedSort = false;
  bool _expandedOrder = false;
  bool _expandedRes = false;
  bool _expandedAtleast = false;
  bool _expandedRatios = false;
  bool _expandedColor = false;
  bool _expandedRating = false;
  bool _expandedCategories = false;
  bool _expandedTimeRange = false;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
    _qCtrl = TextEditingController(text: _f.text);
  }

  @override
  void dispose() {
    _qDebounce?.cancel();
    _qCtrl.dispose();
    super.dispose();
  }

  Color _monoPrimary(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark ? Colors.white : Colors.black;
  }

  void _commit({bool closeExpanded = false}) {
    if (!mounted) return;

    if (closeExpanded) {
      _expandedSort = false;
      _expandedOrder = false;
      _expandedRes = false;
      _expandedAtleast = false;
      _expandedRatios = false;
      _expandedColor = false;
      _expandedRating = false;
      _expandedCategories = false;
      _expandedTimeRange = false;
    }

    widget.onApply(_f.copyWith(text: _qCtrl.text));
  }

  void _debounceQuery(String v) {
    _qDebounce?.cancel();
    _qDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _f = _f.copyWith(text: v));
      _commit();
    });
  }

  Set<T> _toggleSet<T>(Set<T> s, T v) {
    final next = Set<T>.from(s);
    if (next.contains(v)) {
      next.remove(v);
    } else {
      next.add(v);
    }
    return next;
  }

  String _summaryStrings(Set<String> s, {String empty = '不限'}) {
    if (s.isEmpty) return empty;
    final list = s.toList()..sort();
    if (list.length <= 2) return list.join('，');
    return '${list.take(2).join('，')} 等 ${list.length} 项';
  }

  String _summaryEnum<T>(Set<T> s, String Function(T) labelOf, {String empty = '不限'}) {
    if (s.isEmpty) return empty;
    final list = s.toList();
    if (list.length <= 2) return list.map(labelOf).join('，');
    return '${list.take(2).map(labelOf).join('，')} 等 ${list.length} 项';
  }

  String _labelSortBy(SortBy v) {
    switch (v) {
      case SortBy.relevance:
        return '相关';
      case SortBy.newest:
        return '最新';
      case SortBy.views:
        return '浏览';
      case SortBy.favorites:
        return '收藏';
      case SortBy.random:
        return '随机';
      case SortBy.toplist:
        return '榜单';
    }
  }

  String _labelOrder(SortOrder v) => (v == SortOrder.desc) ? '降序' : '升序';

  String _labelRating(RatingLevel v) {
    switch (v) {
      case RatingLevel.safe:
        return '安全';
      case RatingLevel.questionable:
        return '擦边';
      case RatingLevel.explicit:
        return '限制';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);

    // ✅ 从当前 source 拿 capabilities（source 驱动 UI）
    final SourceCapabilities caps = store.currentWallpaperSourceCapabilities;

    final isDark = theme.brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: theme.scaffoldBackgroundColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    final sortValue = _f.sortBy;
    final orderValue = _f.order;

    final selectedRes = _f.resolutions;
    final selectedRatios = _f.ratios;

    final selectedCats = _f.categories;
    final selectedRating = _f.rating;

    String labelOption(List<OptionItem> options, String? id, {String fallback = '-'}) {
      if (id == null || id.isEmpty) return fallback;
      for (final o in options) {
        if (o.id == id) return o.label;
      }
      return fallback;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: SafeArea(
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "筛选",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.onReset();
                            setState(() => _f = const FilterSpec());
                            _qCtrl.text = '';
                            _commit(closeExpanded: true);
                          },
                          child: Text("重置", style: TextStyle(color: mono.withOpacity(0.7))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView(
                        children: [
                          if (caps.supportsText)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _KeywordInput(
                                controller: _qCtrl,
                                onChanged: _debounceQuery,
                              ),
                            ),

                          if (caps.supportsSort)
                            _collapse(
                              context: context,
                              title: '排序方式',
                              valueLabel: sortValue == null ? '-' : _labelSortBy(sortValue),
                              expanded: _expandedSort,
                              onToggle: () => setState(() => _expandedSort = !_expandedSort),
                              child: _singlePickEnum<SortBy>(
                                context: context,
                                options: caps.sortByOptions,
                                value: sortValue ?? (caps.sortByOptions.isNotEmpty ? caps.sortByOptions.first : SortBy.toplist),
                                labelOf: _labelSortBy,
                                onPick: (v) {
                                  setState(() {
                                    _f = _f.copyWith(sortBy: v);
                                    _expandedSort = false;
                                    if (v != SortBy.toplist) _expandedTimeRange = false;
                                  });
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsTimeRange && (_f.sortBy == SortBy.toplist))
                            _collapse(
                              context: context,
                              title: '时间范围',
                              valueLabel: labelOption(caps.timeRangeOptions, _f.timeRange, fallback: '-'),
                              expanded: _expandedTimeRange,
                              onToggle: () => setState(() => _expandedTimeRange = !_expandedTimeRange),
                              child: _singlePickOption(
                                context: context,
                                options: caps.timeRangeOptions,
                                value: _f.timeRange ?? (caps.timeRangeOptions.isNotEmpty ? caps.timeRangeOptions.first.id : ''),
                                onPick: (id) {
                                  setState(() {
                                    _f = _f.copyWith(timeRange: id.isEmpty ? null : id);
                                    _expandedTimeRange = false;
                                  });
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsOrder)
                            _collapse(
                              context: context,
                              title: '排序方向',
                              valueLabel: orderValue == null ? '-' : _labelOrder(orderValue),
                              expanded: _expandedOrder,
                              onToggle: () => setState(() => _expandedOrder = !_expandedOrder),
                              child: _singlePickEnum<SortOrder>(
                                context: context,
                                options: const [SortOrder.desc, SortOrder.asc],
                                value: orderValue ?? SortOrder.desc,
                                labelOf: _labelOrder,
                                onPick: (v) {
                                  setState(() {
                                    _f = _f.copyWith(order: v);
                                    _expandedOrder = false;
                                  });
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsCategories)
                            _collapse(
                              context: context,
                              title: '分类',
                              valueLabel: _summaryStrings(selectedCats),
                              expanded: _expandedCategories,
                              onToggle: () => setState(() => _expandedCategories = !_expandedCategories),
                              child: _multiChipOptions(
                                context: context,
                                options: caps.categoryOptions,
                                selectedIds: selectedCats,
                                onToggle: (id) {
                                  setState(() => _f = _f.copyWith(categories: _toggleSet(selectedCats, id)));
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsRating)
                            _collapse(
                              context: context,
                              title: '分级',
                              valueLabel: _summaryEnum<RatingLevel>(selectedRating, _labelRating),
                              expanded: _expandedRating,
                              onToggle: () => setState(() => _expandedRating = !_expandedRating),
                              child: _multiChipEnum<RatingLevel>(
                                context: context,
                                options: caps.ratingOptions,
                                selected: selectedRating,
                                labelOf: _labelRating,
                                onToggle: (v) {
                                  setState(() => _f = _f.copyWith(rating: _toggleSet(selectedRating, v)));
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsResolutions)
                            _collapse(
                              context: context,
                              title: '分辨率（精确匹配）',
                              valueLabel: _summaryStrings(selectedRes),
                              expanded: _expandedRes,
                              onToggle: () => setState(() => _expandedRes = !_expandedRes),
                              child: _multiChipStrings(
                                context: context,
                                options: caps.resolutionOptions,
                                selected: selectedRes,
                                onToggle: (v) {
                                  setState(() => _f = _f.copyWith(resolutions: _toggleSet(selectedRes, v)));
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsAtleast)
                            _collapse(
                              context: context,
                              title: '最小分辨率（至少）',
                              valueLabel: (_f.atleast ?? '').isEmpty ? '不限' : _f.atleast!,
                              expanded: _expandedAtleast,
                              onToggle: () => setState(() => _expandedAtleast = !_expandedAtleast),
                              child: _singlePickString(
                                context: context,
                                options: caps.atleastOptions,
                                value: _f.atleast ?? '',
                                labelOf: (v) => v.isEmpty ? '不限' : v,
                                onPick: (v) {
                                  setState(() {
                                    _f = _f.copyWith(atleast: v.isEmpty ? null : v);
                                    _expandedAtleast = false;
                                  });
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsRatios)
                            _collapse(
                              context: context,
                              title: '比例',
                              valueLabel: _summaryStrings(selectedRatios),
                              expanded: _expandedRatios,
                              onToggle: () => setState(() => _expandedRatios = !_expandedRatios),
                              child: _multiChipStrings(
                                context: context,
                                options: caps.ratioOptions,
                                selected: selectedRatios,
                                onToggle: (v) {
                                  setState(() => _f = _f.copyWith(ratios: _toggleSet(selectedRatios, v)));
                                  _commit();
                                },
                              ),
                            ),

                          if (caps.supportsColor)
                            _collapse(
                              context: context,
                              title: '颜色（Hex）',
                              valueLabel: (_f.color ?? '').isEmpty ? '不限' : (_f.color ?? '').toUpperCase(),
                              expanded: _expandedColor,
                              onToggle: () => setState(() => _expandedColor = !_expandedColor),
                              child: _singlePickString(
                                context: context,
                                options: [''] + caps.colorOptions,
                                value: _f.color ?? '',
                                labelOf: (v) => v.isEmpty ? '不限' : v.toUpperCase(),
                                onPick: (v) {
                                  setState(() {
                                    _f = _f.copyWith(color: v.isEmpty ? null : v.replaceAll('#', ''));
                                    _expandedColor = false;
                                  });
                                  _commit();
                                },
                              ),
                            ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 16,
                bottom: 16,
                child: _SettingsFab(onTap: widget.onOpenSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapse({
    required BuildContext context,
    required String title,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final r = ThemeScope.of(context).cardRadius;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: mono.withOpacity(0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                      ),
                      const SizedBox(width: 10),
                      Text(valueLabel, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 160),
                        child: Icon(Icons.keyboard_arrow_down, color: mono.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: child,
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 160),
            ),
          ],
        ),
      ),
    );
  }

  Widget _singlePickEnum<T>({
    required BuildContext context,
    required List<T> options,
    required T value,
    required String Function(T) labelOf,
    required ValueChanged<T> onPick,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Column(
      children: options.map((o) {
        final selected = o == value;
        return InkWell(
          onTap: () => onPick(o),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(labelOf(o), style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
                if (selected) Icon(Icons.check, size: 18, color: mono),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _singlePickString({
    required BuildContext context,
    required List<String> options,
    required String value,
    required String Function(String) labelOf,
    required ValueChanged<String> onPick,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Column(
      children: options.map((o) {
        final selected = o == value;
        return InkWell(
          onTap: () => onPick(o),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(labelOf(o), style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
                if (selected) Icon(Icons.check, size: 18, color: mono),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _singlePickOption({
    required BuildContext context,
    required List<OptionItem> options,
    required String value,
    required ValueChanged<String> onPick,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Column(
      children: options.map((o) {
        final selected = o.id == value;
        return InkWell(
          onTap: () => onPick(o.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(o.label, style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
                if (selected) Icon(Icons.check, size: 18, color: mono),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _multiChipStrings({
    required BuildContext context,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = selected.contains(o);
        return InkWell(
          onTap: () => onToggle(o),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(width: 1, color: on ? mono.withOpacity(0.40) : mono.withOpacity(0.12)),
            ),
            child: Text(
              o,
              style: TextStyle(
                fontSize: 14,
                color: on ? mono : theme.textTheme.bodyLarge?.color,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _multiChipEnum<T>({
    required BuildContext context,
    required List<T> options,
    required Set<T> selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onToggle,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = selected.contains(o);
        return InkWell(
          onTap: () => onToggle(o),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(width: 1, color: on ? mono.withOpacity(0.40) : mono.withOpacity(0.12)),
            ),
            child: Text(
              labelOf(o),
              style: TextStyle(
                fontSize: 14,
                color: on ? mono : theme.textTheme.bodyLarge?.color,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _multiChipOptions({
    required BuildContext context,
    required List<OptionItem> options,
    required Set<String> selectedIds,
    required ValueChanged<String> onToggle,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final on = selectedIds.contains(o.id);
        return InkWell(
          onTap: () => onToggle(o.id),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: on ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(width: 1, color: on ? mono.withOpacity(0.40) : mono.withOpacity(0.12)),
            ),
            child: Text(
              o.label,
              style: TextStyle(
                fontSize: 14,
                color: on ? mono : theme.textTheme.bodyLarge?.color,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KeywordInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _KeywordInput({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = ThemeScope.of(context).cardRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Container(
        color: theme.cardColor,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "关键词（留空为不限）",
            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SettingsFab extends StatelessWidget {
  final VoidCallback? onTap;
  const _SettingsFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.settings_outlined, color: theme.iconTheme.color, size: 24),
        ),
      ),
    );
  }
}