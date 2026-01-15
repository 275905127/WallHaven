// lib/pages/filter_drawer.dart
// ⚠️ 警示：筛选项必须与 Wallhaven 官方参数 1:1 对应；文案可中文化但参数值不可乱改。
// ⚠️ 警示：UI 风格只允许黑白灰；禁止引入蓝/绿/红等高饱和“装饰色”。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_store.dart';
import '../theme/app_tokens.dart';

class WallhavenFilters {
  final String query;
  final String sorting; // date_added / relevance / random / views / favorites / toplist
  final String order; // desc / asc
  final String categories; // 111
  final String purity; // 100
  final String resolutions; // "1920x1080,2560x1440" or ""
  final String ratios; // "16x9,21x9" or ""
  final String atleast; // "1920x1080" or ""
  final String colors; // "660000" or ""
  final String topRange; // 1d/3d/1w/1M/3M/6M/1y or ""

  const WallhavenFilters({
    this.query = '',
    this.sorting = 'toplist',
    this.order = 'desc',
    this.categories = '111',
    this.purity = '100',
    this.resolutions = '',
    this.ratios = '',
    this.atleast = '',
    this.colors = '',
    this.topRange = '1M',
  });

  WallhavenFilters copyWith({
    String? query,
    String? sorting,
    String? order,
    String? categories,
    String? purity,
    String? resolutions,
    String? ratios,
    String? atleast,
    String? colors,
    String? topRange,
  }) {
    return WallhavenFilters(
      query: query ?? this.query,
      sorting: sorting ?? this.sorting,
      order: order ?? this.order,
      categories: categories ?? this.categories,
      purity: purity ?? this.purity,
      resolutions: resolutions ?? this.resolutions,
      ratios: ratios ?? this.ratios,
      atleast: atleast ?? this.atleast,
      colors: colors ?? this.colors,
      topRange: topRange ?? this.topRange,
    );
  }
}

class FilterDrawer extends StatefulWidget {
  final WallhavenFilters initial;

  /// ✅ 选中即生效：任何筛选变化都会触发 onApply
  final ValueChanged<WallhavenFilters> onApply;

  /// ✅ 重置（仍保留）
  final VoidCallback onReset;

  /// ✅ 右下角“设置”入口（由外部提供打开设置页的动作）
  /// 这里不直接 import SettingsPage，避免依赖入口文件里的类。
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
  late WallhavenFilters _f;
  late TextEditingController _qCtrl;

  Timer? _qDebounce;

  // 展开状态（全部折叠行）
  bool _sortingExpanded = false;
  bool _topRangeExpanded = false;
  bool _orderExpanded = false;
  bool _categoriesExpanded = false;
  bool _purityExpanded = false;
  bool _resolutionsExpanded = false;
  bool _atleastExpanded = false;
  bool _ratiosExpanded = false;
  bool _colorsExpanded = false;

  // ===== 官方参数值不改：value 必须是 wallhaven 接受的值 =====

  static const List<_PickItem<String>> _sortingItems = [
    _PickItem('toplist', '榜单'),
    _PickItem('date_added', '最新'),
    _PickItem('favorites', '收藏'),
    _PickItem('views', '浏览'),
    _PickItem('random', '随机'),
    _PickItem('relevance', '相关'),
  ];

  static const List<_PickItem<String>> _orderItems = [
    _PickItem('desc', '降序'),
    _PickItem('asc', '升序'),
  ];

  static const List<_PickItem<String>> _topRangeItems = [
    _PickItem('1d', '1 天'),
    _PickItem('3d', '3 天'),
    _PickItem('1w', '1 周'),
    _PickItem('1M', '1 月'),
    _PickItem('3M', '3 月'),
    _PickItem('6M', '6 月'),
    _PickItem('1y', '1 年'),
  ];

  static const List<String> _resolutionOptions = [
    '1280x720',
    '1366x768',
    '1600x900',
    '1920x1080',
    '1920x1200',
    '2560x1440',
    '2560x1600',
    '3440x1440',
    '3840x2160',
    '1080x1920',
    '1440x2560',
    '2160x3840',
  ];

  static const List<String> _atleastOptions = [
    '',
    '1280x720',
    '1600x900',
    '1920x1080',
    '2560x1440',
    '3440x1440',
    '3840x2160',
    '1080x1920',
    '1440x2560',
    '2160x3840',
  ];

  static const List<String> _ratioOptions = [
    '16x9',
    '16x10',
    '21x9',
    '32x9',
    '4x3',
    '3x2',
    '5x4',
    '1x1',
    '9x16',
    '10x16',
  ];

  static const List<String> _colorOptions = [
    '000000',
    '111111',
    '222222',
    '333333',
    '444444',
    '555555',
    '666666',
    '777777',
    '888888',
    '999999',
    'AAAAAA',
    'BBBBBB',
    'CCCCCC',
    'DDDDDD',
    'EEEEEE',
    'FFFFFF',
    '660000',
    '006600',
    '000066',
    '663300',
    '003366',
    '660066',
  ];

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
    _qCtrl = TextEditingController(text: _f.query);
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

  // =========================
  // ✅ 选中即生效（统一出口）
  // =========================
  void _commitApply({bool closeExpanded = false}) {
    if (!mounted) return;

    if (closeExpanded) {
      _sortingExpanded = false;
      _topRangeExpanded = false;
      _orderExpanded = false;
      _categoriesExpanded = false;
      _purityExpanded = false;
      _resolutionsExpanded = false;
      _atleastExpanded = false;
      _ratiosExpanded = false;
      _colorsExpanded = false;
    }

    final next = _f.copyWith(query: _qCtrl.text);
    widget.onApply(next);
  }

  void _debounceQueryApply(String v) {
    _qDebounce?.cancel();
    _qDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _f = _f.copyWith(query: v));
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
    final r = tokens.smallRadius;
    if (length == 1) return BorderRadius.circular(r);
    return BorderRadius.circular(r);
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

  Widget _singlePickList({
    required BuildContext context,
    required List<_PickItem<String>> items,
    required String value,
    required ValueChanged<String> onPick,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Column(
      children: List.generate(items.length, (i) {
        final it = items[i];
        final selected = it.value == value;
        final br = _subRadiusFor(context, i, items.length);
        final isLast = i == items.length - 1;

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

  Widget _multiCheckList({
    required BuildContext context,
    required List<_CheckItem> items,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return Column(
      children: List.generate(items.length, (i) {
        final it = items[i];
        final br = _subRadiusFor(context, i, items.length);
        final isLast = i == items.length - 1;

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
                  onTap: () => it.onChanged(!it.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: it.value,
                          onChanged: (v) => it.onChanged(v ?? false),
                          checkColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                          fillColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) return mono;
                            return mono.withOpacity(0.08);
                          }),
                          side: BorderSide(color: mono.withOpacity(0.18)),
                        ),
                        Expanded(
                          child: Text(
                            it.label,
                            style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                          ),
                        ),
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

  Set<String> _csvToSet(String csv) {
    final s = csv.trim();
    if (s.isEmpty) return <String>{};
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }

  String _setToCsv(Set<String> set) {
    if (set.isEmpty) return '';
    final list = set.toList()..sort();
    return list.join(',');
  }

  String _labelFromPick(List<_PickItem<String>> items, String value, {String fallback = '-'}) {
    for (final it in items) {
      if (it.value == value) return it.label;
    }
    return fallback;
  }

  String _summaryCsv(String csv, {String empty = '不限'}) {
    final set = _csvToSet(csv);
    if (set.isEmpty) return empty;
    final list = set.toList()..sort();
    if (list.length <= 2) return list.join('，');
    return '${list.take(2).join('，')} 等 ${list.length} 项';
  }

  String _summaryCategories() {
    final s = _f.categories.padRight(3, '1');
    final List<String> on = [];
    if (s.isNotEmpty && s[0] == '1') on.add('常规');
    if (s.length > 1 && s[1] == '1') on.add('动漫');
    if (s.length > 2 && s[2] == '1') on.add('人物');
    if (on.isEmpty) return '不限';
    return on.join('，');
  }

  String _summaryPurity() {
    final s = _f.purity.padRight(3, '0');
    final List<String> on = [];
    if (s.isNotEmpty && s[0] == '1') on.add('SFW');
    if (s.length > 1 && s[1] == '1') on.add('Sketchy');
    if (s.length > 2 && s[2] == '1') on.add('NSFW');
    if (on.isEmpty) return '不限';
    return on.join('，');
  }

  String _summaryAtleast() {
    final v = _f.atleast.trim();
    return v.isEmpty ? '不限' : v;
  }

  String _summaryColor() {
    final v = _f.colors.trim().replaceAll('#', '');
    return v.isEmpty ? '不限' : v.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    // ✅ 抽屉页期望：状态栏与筛选页背景同步（如果没生效，是被 AppBar/systemOverlayStyle 覆盖了）
    final isDark = theme.brightness == Brightness.dark;
    final overlay = SystemUiOverlayStyle(
      statusBarColor: theme.scaffoldBackgroundColor,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: theme.scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    final selectedRes = _csvToSet(_f.resolutions);
    final selectedRatios = _csvToSet(_f.ratios);
    final colorsValue = _f.colors.trim().replaceAll('#', '');

    final rowDefs = <_RowDef>[
      _RowDef(
        title: '排序方式',
        valueLabel: _labelFromPick(_sortingItems, _f.sorting, fallback: _f.sorting),
        expanded: _sortingExpanded,
        onToggle: () => setState(() => _sortingExpanded = !_sortingExpanded),
        child: _singlePickList(
          context: context,
          items: _sortingItems,
          value: _f.sorting,
          onPick: (v) {
            setState(() {
              _f = _f.copyWith(sorting: v);
              _sortingExpanded = false;
              if (v != 'toplist') _topRangeExpanded = false;
            });
            _commitApply();
          },
        ),
      ),
      if (_f.sorting == 'toplist')
        _RowDef(
          title: '榜单时间范围',
          valueLabel: _labelFromPick(_topRangeItems, _f.topRange, fallback: _f.topRange),
          expanded: _topRangeExpanded,
          onToggle: () => setState(() => _topRangeExpanded = !_topRangeExpanded),
          child: _singlePickList(
            context: context,
            items: _topRangeItems,
            value: _f.topRange,
            onPick: (v) {
              setState(() {
                _f = _f.copyWith(topRange: v);
                _topRangeExpanded = false;
              });
              _commitApply();
            },
          ),
        ),
      _RowDef(
        title: '排序方向',
        valueLabel: _labelFromPick(_orderItems, _f.order, fallback: _f.order),
        expanded: _orderExpanded,
        onToggle: () => setState(() => _orderExpanded = !_orderExpanded),
        child: _singlePickList(
          context: context,
          items: _orderItems,
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
      _RowDef(
        title: '分类',
        valueLabel: _summaryCategories(),
        expanded: _categoriesExpanded,
        onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
        child: _multiCheckList(
          context: context,
          items: [
            _CheckItem(
              label: '常规',
              value: _f.categories.length > 0 ? _f.categories[0] == '1' : true,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(categories: _bit3(_f.categories, 0, v, defaultPad: '1')));
                _commitApply();
              },
            ),
            _CheckItem(
              label: '动漫',
              value: _f.categories.length > 1 ? _f.categories[1] == '1' : true,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(categories: _bit3(_f.categories, 1, v, defaultPad: '1')));
                _commitApply();
              },
            ),
            _CheckItem(
              label: '人物',
              value: _f.categories.length > 2 ? _f.categories[2] == '1' : true,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(categories: _bit3(_f.categories, 2, v, defaultPad: '1')));
                _commitApply();
              },
            ),
          ],
        ),
      ),
      _RowDef(
        title: '分级',
        valueLabel: _summaryPurity(),
        expanded: _purityExpanded,
        onToggle: () => setState(() => _purityExpanded = !_purityExpanded),
        child: _multiCheckList(
          context: context,
          items: [
            _CheckItem(
              label: 'SFW',
              value: _f.purity.length > 0 ? _f.purity[0] == '1' : true,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(purity: _bit3(_f.purity, 0, v, defaultPad: '0')));
                _commitApply();
              },
            ),
            _CheckItem(
              label: 'Sketchy',
              value: _f.purity.length > 1 ? _f.purity[1] == '1' : false,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(purity: _bit3(_f.purity, 1, v, defaultPad: '0')));
                _commitApply();
              },
            ),
            _CheckItem(
              label: 'NSFW',
              value: _f.purity.length > 2 ? _f.purity[2] == '1' : false,
              onChanged: (v) {
                setState(() => _f = _f.copyWith(purity: _bit3(_f.purity, 2, v, defaultPad: '0')));
                _commitApply();
              },
            ),
          ],
        ),
      ),
      _RowDef(
        title: '分辨率（精确匹配）',
        valueLabel: _summaryCsv(_f.resolutions),
        expanded: _resolutionsExpanded,
        onToggle: () => setState(() => _resolutionsExpanded = !_resolutionsExpanded),
        child: _multiChipPicker(
          context: context,
          options: _resolutionOptions,
          selected: selectedRes,
          onChanged: (set) {
            setState(() => _f = _f.copyWith(resolutions: _setToCsv(set)));
            _commitApply();
          },
        ),
      ),
      _RowDef(
        title: '最小分辨率（至少）',
        valueLabel: _summaryAtleast(),
        expanded: _atleastExpanded,
        onToggle: () => setState(() => _atleastExpanded = !_atleastExpanded),
        child: _singlePickList(
          context: context,
          items: [
            const _PickItem('', '不限'),
            ..._atleastOptions.where((e) => e.isNotEmpty).map((e) => _PickItem(e, e)),
          ],
          value: _f.atleast.trim(),
          onPick: (v) {
            setState(() {
              _f = _f.copyWith(atleast: v.trim());
              _atleastExpanded = false;
            });
            _commitApply();
          },
        ),
      ),
      _RowDef(
        title: '比例',
        valueLabel: _summaryCsv(_f.ratios),
        expanded: _ratiosExpanded,
        onToggle: () => setState(() => _ratiosExpanded = !_ratiosExpanded),
        child: _multiChipPicker(
          context: context,
          options: _ratioOptions,
          selected: selectedRatios,
          onChanged: (set) {
            setState(() => _f = _f.copyWith(ratios: _setToCsv(set)));
            _commitApply();
          },
        ),
      ),
      _RowDef(
        title: '颜色（十六进制）',
        valueLabel: _summaryColor(),
        expanded: _colorsExpanded,
        onToggle: () => setState(() => _colorsExpanded = !_colorsExpanded),
        child: _singlePickList(
          context: context,
          items: [
            const _PickItem('', '不限'),
            ..._colorOptions.map((c) => _PickItem(c, c.toUpperCase())),
          ],
          value: colorsValue,
          onPick: (v) {
            setState(() {
              _f = _f.copyWith(colors: v.trim().replaceAll('#', ''));
              _colorsExpanded = false;
            });
            _commitApply();
          },
        ),
      ),
    ];

    final groupRows = <Widget>[];
    for (int i = 0; i < rowDefs.length; i++) {
      final def = rowDefs[i];
      final br = _groupRadiusFor(context, i, rowDefs.length);
      groupRows.add(
        _groupCollapseRow(
          context: context,
          title: def.title,
          valueLabel: def.valueLabel,
          expanded: def.expanded,
          onToggle: def.onToggle,
          expandedChild: def.child,
          borderRadius: br,
          showBottomGap: i != rowDefs.length - 1,
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
                            setState(() => _f = const WallhavenFilters());
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
                          // ✅ 搜索框：卡片底色；无描边；提示在 hint；不再单独“关键词”标题 → 整体上移
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

              // ✅ 设置按钮：仅图标，无底色/无描边
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

// ====== 小组件：关键词输入（不折叠）======

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

    // ✅ 用 Container 承担“卡片底色 + 圆角裁切”，TextField 内部彻底无 border
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

// ====== tiny models ======

class _PickItem<T> {
  final T value;
  final String label;
  const _PickItem(this.value, this.label);
}

class _CheckItem {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  _CheckItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });
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

// 3 位 bit helper：categories 默认 pad '1'，purity 默认 pad '0'
String _bit3(String old, int index, bool on, {required String defaultPad}) {
  final chars = old.padRight(3, defaultPad).split('');
  if (index >= 0 && index < 3) chars[index] = on ? '1' : '0';
  return chars.take(3).join();
}