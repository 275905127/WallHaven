// lib/pages/filter_drawer.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/entities/filter_spec.dart';
import '../domain/entities/source_capabilities.dart';
import '../domain/entities/option_item.dart';
import '../theme/theme_store.dart';
import '../theme/app_tokens.dart';

class FilterDrawer extends StatefulWidget {
  /// ✅ 通用：domain filters
  final FilterSpec initial;

  /// ✅ 选中即生效
  final ValueChanged<FilterSpec> onApply;

  /// ✅ 重置
  final VoidCallback onReset;

  /// ✅ 设置入口
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

  // 展开状态
  bool _sortExpanded = false;
  bool _orderExpanded = false;
  bool _ratingExpanded = false;
  bool _categoriesExpanded = false;
  bool _timeRangeExpanded = false;
  bool _resolutionsExpanded = false;
  bool _atleastExpanded = false;
  bool _ratiosExpanded = false;
  bool _colorExpanded = false;

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

  // -------------------------
  // ✅ commit apply (single exit)
  // -------------------------
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

  // -------------------------
  // UI helpers
  // -------------------------
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

  // -------------------------
  // pickers
  // -------------------------
  Widget _singlePickList<T>({
    required BuildContext context,
    required List<_PickItem<T>> items,
    required T? value,
    required ValueChanged<T> onPick,
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
                  onTap: () {
                    final v = it.value;
                    if (v != null) onPick(v as T);
                    else {
                      // clear
                      // caller handles null via copyWith
                      onPick as dynamic;
                    }
                  },
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
          if (on) {
            next.remove(text);
          } else {
            next.add(text);
          }
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

  // -------------------------
  // labels / summaries
  // -------------------------
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

  // -------------------------
  // build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    final store = ThemeScope.of(context);

    // ✅ 必须由 source 决定能力
    // 你的 data/sourceFactory 已经能从 store 取到 source，
    // 但 UI 层不应 import data。这里直接用 ThemeStore 提供的 currentPlugin capabilities。
    //
    // 现在你 ThemeStore 还没有暴露 “capabilities”，你必须加一个 getter：
    //   SourceCapabilities get currentCapabilities => _factory.fromStore(this).capabilities;
    //
    // 临时：先走 currentPluginSettings + pluginId 判断是不够的。
    //
    // 这里我假定你已经在 ThemeStore 加了：
    //   SourceCapabilities get currentCapabilities
    final SourceCapabilities caps = store.currentCapabilities;

    // ✅ 抽屉页 overlay
    final isDark = theme.brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: theme.scaffoldBackgroundColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    // Row defs
    final rows = <_RowDef>[];

    // Sort
    if (caps.supportsSort && caps.sortByOptions.isNotEmpty) {
      final items = caps.sortByOptions.map((e) => _PickItem<SortBy>(e, _sortLabel(e))).toList();
      rows.add(
        _RowDef(
          title: '排序方式',
          valueLabel: _f.sortBy == null ? '不限' : _sortLabel(_f.sortBy!),
          expanded: _sortExpanded,
          onToggle: () => setState(() => _sortExpanded = !_sortExpanded),
          child: _singlePickListNullable<SortBy>(
            context: context,
            items: items,
            value: _f.sortBy,
            onPick: (v) {
              setState(() {
                _f = _f.copyWith(sortBy: v);
                _sortExpanded = false;
                // sortBy 改了可能导致 timeRange 不适用（由 source 决定；这里不强行清）
              });
              _commitApply();
            },
          ),
        ),
      );
    }

    // TimeRange
    if (caps.supportsTimeRange && caps.timeRangeOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '时间范围',
          valueLabel: _f.timeRange == null || _f.timeRange!.trim().isEmpty
              ? '不限'
              : _summaryOptions({_f.timeRange!}, caps.timeRangeOptions),
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

    // Order
    if (caps.supportsOrder) {
      final items = [
        _PickItem<SortOrder>(SortOrder.desc, '降序'),
        _PickItem<SortOrder>(SortOrder.asc, '升序'),
      ];
      rows.add(
        _RowDef(
          title: '排序方向',
          valueLabel: _f.order == null ? '不限' : _orderLabel(_f.order!),
          expanded: _orderExpanded,
          onToggle: () => setState(() => _orderExpanded = !_orderExpanded),
          child: _singlePickListNullable<SortOrder>(
            context: context,
            items: items,
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

    // Categories (source-defined)
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

    // Rating (safe/questionable/explicit)
    if (caps.supportsRating && caps.ratingOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '内容等级',
          valueLabel: _summaryRating(_f.rating),
          expanded: _ratingExpanded,
          onToggle: () => setState(() => _ratingExpanded = !_ratingExpanded),
          child: _multiOptionPicker(
            context: context,
            options: caps.ratingOptions
                .map((r) => OptionItem(id: r.name, label: _ratingLabel(r)))
                .toList(),
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

    // Resolutions
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

    // Atleast
    if (caps.supportsAtleast && caps.atleastOptions.isNotEmpty) {
      rows.add(
        _RowDef(
          title: '最小分辨率（至少）',
          valueLabel: (_f.atleast ?? '').trim().isEmpty ? '不限' : _f.atleast!.trim(),
          expanded: _atleastExpanded,
          onToggle: () => setState(() => _atleastExpanded = !_atleastExpanded),
          child: _singlePickListNullable<String>(
            context: context,
            items: caps.atleastOptions
                .map((e) => _PickItem<String>(e, e.isEmpty ? '不限' : e))
                .toList(),
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

    // Ratios
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

    // Color
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
            emptyLabel: '不限',
          ),
        ),
      );
    }

    // group rows render
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

// ====== Keyword input ======
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

// tiny models
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

// ---------------------------
// ✅ 可选：FilterSpec JSON 持久化工具（给 main.dart 用）
// 你要持久化就 copy 这俩函数到你想放的地方。
// ---------------------------
String filterSpecToJsonString(FilterSpec f) {
  final map = <String, dynamic>{
    'text': f.text,
    'sortBy': f.sortBy?.name,
    'order': f.order?.name,
    'resolutions': f.resolutions.toList(),
    'atleast': f.atleast,
    'ratios': f.ratios.toList(),
    'color': f.color,
    'rating': f.rating.map((e) => e.name).toList(),
    'categories': f.categories.toList(),
    'timeRange': f.timeRange,
  };
  return jsonEncode(map);
}

FilterSpec filterSpecFromJsonString(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return const FilterSpec();
  final m = decoded.cast<String, dynamic>();

  SortBy? sortBy;
  final sb = m['sortBy'];
  if (sb is String) {
    for (final e in SortBy.values) {
      if (e.name == sb) sortBy = e;
    }
  }

  SortOrder? order;
  final od = m['order'];
  if (od is String) {
    for (final e in SortOrder.values) {
      if (e.name == od) order = e;
    }
  }

  final resolutions = <String>{};
  final rr = m['resolutions'];
  if (rr is List) {
    for (final e in rr) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) resolutions.add(s);
    }
  }

  final ratios = <String>{};
  final ra = m['ratios'];
  if (ra is List) {
    for (final e in ra) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) ratios.add(s);
    }
  }

  final rating = <RatingLevel>{};
  final rt = m['rating'];
  if (rt is List) {
    for (final e in rt) {
      final s = e?.toString().trim() ?? '';
      for (final r in RatingLevel.values) {
        if (r.name == s) rating.add(r);
      }
    }
  }

  final categories = <String>{};
  final cc = m['categories'];
  if (cc is List) {
    for (final e in cc) {
      final s = e?.toString().trim() ?? '';
      if (s.isNotEmpty) categories.add(s);
    }
  }

  final text = (m['text'] ?? '').toString();
  final atleast = (m['atleast'] ?? '').toString().trim();
  final color = (m['color'] ?? '').toString().trim();
  final timeRange = (m['timeRange'] ?? '').toString().trim();

  return FilterSpec(
    text: text,
    sortBy: sortBy,
    order: order,
    resolutions: resolutions,
    atleast: atleast.isEmpty ? null : atleast,
    ratios: ratios,
    color: color.isEmpty ? null : color.replaceAll('#', ''),
    rating: rating,
    categories: categories,
    timeRange: timeRange.isEmpty ? null : timeRange,
  );
}