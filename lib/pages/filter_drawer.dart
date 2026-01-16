// lib/pages/filter_drawer.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/entities/dynamic_filter.dart';
import '../domain/entities/filter_spec.dart';
import '../domain/entities/source_capabilities.dart';
import '../domain/entities/option_item.dart';
import '../theme/theme_store.dart';
import '../theme/app_tokens.dart';

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

  bool _sortExpanded = false;
  bool _orderExpanded = false;
  bool _ratingExpanded = false;
  bool _categoriesExpanded = false;
  bool _timeRangeExpanded = false;
  bool _resolutionsExpanded = false;
  bool _atleastExpanded = false;
  bool _ratiosExpanded = false;
  bool _colorExpanded = false;

  /// ✅ 动态筛选展开状态：key=paramName
  final Map<String, bool> _dynExpanded = {};

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

  void _commitApply({bool closeExpanded = false}) {
    if (!mounted) return;

    if (closeExpanded) {
      _sortExpanded = false;
      _orderExpanded = false;
      _ratingExpanded = false;
      _categoriesExpanded = false;
      _timeRangeExpanded = false;
      _resolutionsExpanded = false;
      _atleastExpanded = false;
      _ratiosExpanded = false;
      _colorExpanded = false;
      _dynExpanded.clear();
    }

    final next = _f.copyWith(text: _qCtrl.text);
    widget.onApply(next);
  }

  void _debounceQueryApply(String v) {
    _qDebounce?.cancel();
    _qDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _f = _f.copyWith(text: v));
      _commitApply();
    });
  }

  BorderRadius _groupRadiusFor(BuildContext context, int index, int length) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final largeRadius = ThemeScope.of(context).cardRadius;
    final small = tokens.smallRadius;

    final isFirst = index == 0;
    final isLast = index == length - 1;
    final isSingle = length == 1;

    if (isSingle) return BorderRadius.circular(largeRadius);

    if (isFirst) {
      return BorderRadius.only(
        topLeft: Radius.circular(largeRadius),
        topRight: Radius.circular(largeRadius),
        bottomLeft: Radius.circular(small),
        bottomRight: Radius.circular(small),
      );
    }

    if (isLast) {
      return BorderRadius.only(
        topLeft: Radius.circular(small),
        topRight: Radius.circular(small),
        bottomLeft: Radius.circular(largeRadius),
        bottomRight: Radius.circular(largeRadius),
      );
    }

    return BorderRadius.circular(small);
  }

  Widget _groupGap(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      height: tokens.dividerThickness,
      color: tokens.dividerColor,
    );
  }

  BorderRadius _subRadiusFor(BuildContext context, int index, int length) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return BorderRadius.circular(tokens.smallRadius);
  }

  Widget _groupCollapseRow({
    required BuildContext context,
    required String title,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget expandedChild,
    required BorderRadius borderRadius,
    required bool showBottomGap,
  }) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: borderRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          valueLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0.0,
                          duration: tokens.expandDuration,
                          curve: tokens.expandCurve,
                          child: Icon(Icons.keyboard_arrow_down, color: tokens.chevronColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    _groupGap(context),
                    expandedChild,
                  ],
                ),
                crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: tokens.expandDuration,
                firstCurve: tokens.expandCurve,
                secondCurve: tokens.expandCurve,
              ),
            ],
          ),
        ),
        if (showBottomGap) _groupGap(context),
      ],
    );
  }

  Widget _singlePickListNullable<T>({
    required BuildContext context,
    required List<_PickItem<T>> items,
    required T? value,
    required ValueChanged<T?> onPick,
    String emptyLabel = '不限',
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    final list = <_PickItem<T?>>[
      _PickItem<T?>(null, emptyLabel),
      ...items.map((e) => _PickItem<T?>(e.value, e.label)),
    ];

    return Column(
      children: List.generate(list.length, (i) {
        final it = list[i];
        final selected = it.value == value;
        final br = _subRadiusFor(context, i, list.length);
        final isLast = i == list.length - 1;

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: br,
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onPick(it.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected) Icon(Icons.check, size: 18, color: mono),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!isLast) _groupGap(context),
          ],
        );
      }),
    );
  }

  Widget _multiChipPicker({
    required BuildContext context,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    Widget chip(String text, bool on) {
      return InkWell(
        onTap: () {
          final next = Set<String>.from(selected);
          if (on) next.remove(text);
          else next.add(text);
          onChanged(next);
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: on ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              width: 1,
              color: on ? mono.withOpacity(0.40) : mono.withOpacity(0.12),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: on ? mono : theme.textTheme.bodyLarge?.color,
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((o) => chip(o, selected.contains(o))).toList(),
      ),
    );
  }

  Widget _multiOptionPicker({
    required BuildContext context,
    required List<OptionItem> options,
    required Set<String> selectedIds,
    required ValueChanged<Set<String>> onChanged,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    Widget chip(OptionItem it, bool on) {
      return InkWell(
        onTap: () {
          final next = Set<String>.from(selectedIds);
          if (on) next.remove(it.id);
          else next.add(it.id);
          onChanged(next);
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: on ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              width: 1,
              color: on ? mono.withOpacity(0.40) : mono.withOpacity(0.12),
            ),
          ),
          child: Text(
            it.label,
            style: TextStyle(
              fontSize: 14,
              color: on ? mono : theme.textTheme.bodyLarge?.color,
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((o) => chip(o, selectedIds.contains(o.id))).toList(),
      ),
    );
  }

  // ========== Dynamic (radio) ==========
  String _dynSummary(DynamicFilter d) {
    final v = _f.extras[d.paramName];
    final s = (v == null) ? '' : v.toString();
    if (s.trim().isEmpty) return '不限';

    // 尝试把 value 映射回 label
    for (final o in d.options) {
      if (o.value == s) return o.label;
    }
    return s;
  }

  Widget _dynamicRadioPicker({
    required BuildContext context,
    required DynamicFilter d,
  }) {
    // null/空字符串 都视为未选
    final current = _f.extras[d.paramName];
    final currentStr = (current == null) ? null : current.toString();

    final items = d.options
        .map((o) => _PickItem<String>(o.value, o.label))
        .toList();

    return _singlePickListNullable<String>(
      context: context,
      items: items,
      value: (currentStr == null || currentStr.trim().isEmpty) ? null : currentStr,
      onPick: (v) {
        setState(() {
          final vv = (v ?? '').toString();
          if (vv.trim().isEmpty) {
            _f = _f.removeExtra(d.paramName);
          } else {
            _f = _f.putExtra(d.paramName, vv);
          }
          _dynExpanded[d.paramName] = false;
        });
        _commitApply();
      },
    );
  }

  // labels
  String _sortLabel(SortBy v) {
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

  String _orderLabel(SortOrder v) => v == SortOrder.asc ? '升序' : '降序';

  String _ratingLabel(RatingLevel v) {
    switch (v) {
      case RatingLevel.safe:
        return '安全';
      case RatingLevel.questionable:
        return '擦边';
      case RatingLevel.explicit:
        return '限制';
    }
  }

  String _summarySet(Set<String> set, {String empty = '不限'}) {
    if (set.isEmpty) return empty;
    final list = set.toList()..sort();
    if (list.length <= 2) return list.join('，');
    return '${list.take(2).join('，')} 等 ${list.length} 项';
  }

  String _summaryOptions(Set<String> selected, List<OptionItem> options, {String empty = '不限'}) {
    if (selected.isEmpty) return empty;
    final map = {for (final o in options) o.id: o.label};
    final labels = selected.map((id) => map[id] ?? id).toList()..sort();
    if (labels.length <= 2) return labels.join('，');
    return '${labels.take(2).join('，')} 等 ${labels.length} 项';
  }

  String _summaryRating(Set<RatingLevel> r, {String empty = '不限'}) {
    if (r.isEmpty) return empty;
    final labels = r.map(_ratingLabel).toList()..sort();
    if (labels.length <= 2) return labels.join('，');
    return '${labels.take(2).join('，')} 等 ${labels.length} 项';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final store = ThemeScope.of(context);

    // ✅ 由当前 source 决定能力
    final SourceCapabilities caps = store.currentCapabilities;

    final isDark = theme.brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: theme.scaffoldBackgroundColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    final rows = <_RowDef>[];

    if (caps.supportsSort && caps.sortByOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '排序方式',
          valueLabel: _f.sortBy == null ? '不限' : _sortLabel(_f.sortBy!),
          expanded: _sortExpanded,
          onToggle: () => setState(() => _sortExpanded = !_sortExpanded),
          child: _singlePickListNullable<SortBy>(
            context: context,
            items: caps.sortByOptions.map((e) => _PickItem<SortBy>(e, _sortLabel(e))).toList(),
            value: _f.sortBy,
            onPick: (v) {
              setState(() {
                _f = _f.copyWith(sortBy: v);
                _sortExpanded = false;
              });
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsTimeRange && caps.timeRangeOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '时间范围',
          valueLabel: (_f.timeRange ?? '').trim().isEmpty ? '不限' : _summaryOptions({_f.timeRange!}, caps.timeRangeOptions),
          expanded: _timeRangeExpanded,
          onToggle: () => setState(() => _timeRangeExpanded = !_timeRangeExpanded),
          child: _singlePickListNullable<String>(
            context: context,
            items: caps.timeRangeOptions.map((o) => _PickItem<String>(o.id, o.label)).toList(),
            value: (_f.timeRange ?? '').trim().isEmpty ? null : _f.timeRange,
            onPick: (v) {
              setState(() {
                _f = _f.copyWith(timeRange: v);
                _timeRangeExpanded = false;
              });
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsOrder) {
      rows.add(
        _RowDef(
          title: '排序方向',
          valueLabel: _f.order == null ? '不限' : _orderLabel(_f.order!),
          expanded: _orderExpanded,
          onToggle: () => setState(() => _orderExpanded = !_orderExpanded),
          child: _singlePickListNullable<SortOrder>(
            context: context,
            items: const [
              _PickItem<SortOrder>(SortOrder.desc, '降序'),
              _PickItem<SortOrder>(SortOrder.asc, '升序'),
            ],
            value: _f.order,
            onPick: (v) {
              setState(() {
                _f = _f.copyWith(order: v);
                _orderExpanded = false;
              });
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsCategories && caps.categoryOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '分类',
          valueLabel: _summaryOptions(_f.categories, caps.categoryOptions),
          expanded: _categoriesExpanded,
          onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
          child: _multiOptionPicker(
            context: context,
            options: caps.categoryOptions,
            selectedIds: _f.categories,
            onChanged: (set) {
              setState(() => _f = _f.copyWith(categories: set));
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsRating && caps.ratingOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '内容等级',
          valueLabel: _summaryRating(_f.rating),
          expanded: _ratingExpanded,
          onToggle: () => setState(() => _ratingExpanded = !_ratingExpanded),
          child: _multiOptionPicker(
            context: context,
            options: caps.ratingOptions.map((r) => OptionItem(id: r.name, label: _ratingLabel(r))).toList(),
            selectedIds: _f.rating.map((e) => e.name).toSet(),
            onChanged: (set) {
              final next = <RatingLevel>{};
              for (final id in set) {
                for (final r in RatingLevel.values) {
                  if (r.name == id) next.add(r);
                }
              }
              setState(() => _f = _f.copyWith(rating: next));
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsResolutions && caps.resolutionOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '分辨率（精确匹配）',
          valueLabel: _summarySet(_f.resolutions),
          expanded: _resolutionsExpanded,
          onToggle: () => setState(() => _resolutionsExpanded = !_resolutionsExpanded),
          child: _multiChipPicker(
            context: context,
            options: caps.resolutionOptions,
            selected: _f.resolutions,
            onChanged: (set) {
              setState(() => _f = _f.copyWith(resolutions: set));
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsAtleast && caps.atleastOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '最小分辨率（至少）',
          valueLabel: (_f.atleast ?? '').trim().isEmpty ? '不限' : _f.atleast!.trim(),
          expanded: _atleastExpanded,
          onToggle: () => setState(() => _atleastExpanded = !_atleastExpanded),
          child: _singlePickListNullable<String>(
            context: context,
            items: caps.atleastOptions.map((e) => _PickItem<String>(e, e.isEmpty ? '不限' : e)).toList(),
            value: (_f.atleast ?? '').trim().isEmpty ? null : _f.atleast,
            onPick: (v) {
              setState(() {
                _f = _f.copyWith(atleast: v);
                _atleastExpanded = false;
              });
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsRatios && caps.ratioOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '比例',
          valueLabel: _summarySet(_f.ratios),
          expanded: _ratiosExpanded,
          onToggle: () => setState(() => _ratiosExpanded = !_ratiosExpanded),
          child: _multiChipPicker(
            context: context,
            options: caps.ratioOptions,
            selected: _f.ratios,
            onChanged: (set) {
              setState(() => _f = _f.copyWith(ratios: set));
              _commitApply();
            },
          ),
        ),
      );
    }

    if (caps.supportsColor && caps.colorOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '颜色（十六进制）',
          valueLabel: (_f.color ?? '').trim().isEmpty ? '不限' : _f.color!.trim().toUpperCase(),
          expanded: _colorExpanded,
          onToggle: () => setState(() => _colorExpanded = !_colorExpanded),
          child: _singlePickListNullable<String>(
            context: context,
            items: caps.colorOptions.map((c) => _PickItem<String>(c, c.toUpperCase())).toList(),
            value: (_f.color ?? '').trim().isEmpty ? null : _f.color!.trim().replaceAll('#', ''),
            onPick: (v) {
              setState(() {
                final vv = (v ?? '').trim().replaceAll('#', '');
                _f = _f.copyWith(color: vv.isEmpty ? null : vv);
                _colorExpanded = false;
              });
              _commitApply();
            },
          ),
        ),
      );
    }

    // ✅ Dynamic filters（radio）
    if (caps.dynamicFilters.isNotEmpty) {
      for (final d in caps.dynamicFilters) {
        // 只支持 radio（你 current model 也是 radio）
        if (d.type != DynamicFilterType.radio) continue;

        final expanded = _dynExpanded[d.paramName] ?? false;
        rows.add(
          _RowDef(
            title: d.title,
            valueLabel: _dynSummary(d),
            expanded: expanded,
            onToggle: () => setState(() => _dynExpanded[d.paramName] = !expanded),
            child: _dynamicRadioPicker(context: context, d: d),
          ),
        );
      }
    }

    final groupRows = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      final def = rows[i];
      final br = _groupRadiusFor(context, i, rows.length);

      groupRows.add(
        _groupCollapseRow(
          context: context,
          title: def.title,
          valueLabel: def.valueLabel,
          expanded: def.expanded,
          onToggle: def.onToggle,
          expandedChild: def.child,
          borderRadius: br,
          showBottomGap: i != rows.length - 1,
        ),
      );
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
                            _commitApply(closeExpanded: true);
                          },
                          child: Text(
                            "重置",
                            style: TextStyle(color: mono.withOpacity(0.7)),
                          ),
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
                                onChanged: _debounceQueryApply,
                              ),
                            ),
                          ...groupRows,
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
          child: Icon(
            Icons.settings_outlined,
            color: theme.iconTheme.color,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _PickItem<T> {
  final T value;
  final String label;
  const _PickItem(this.value, this.label);
}

class _RowDef {
  final String title;
  final String valueLabel;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  _RowDef({
    required this.title,
    required this.valueLabel,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });
}