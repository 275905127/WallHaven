// lib/pages/filter_drawer.dart
// ⚠️ 警示：筛选项必须与 Wallhaven 官方参数 1:1 对应；文案可中文化但参数值不可乱改。
// ⚠️ 警示：UI 风格只允许黑白灰；禁止引入蓝/绿/红等高饱和“装饰色”。

import 'package:flutter/material.dart';
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
  final ValueChanged<WallhavenFilters> onApply;
  final VoidCallback onReset;

  const FilterDrawer({
    super.key,
    required this.initial,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late WallhavenFilters _f;
  late TextEditingController _qCtrl;

  // 折叠状态：全部做成折叠
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

  // 常用分辨率（官网同类常见项），参数格式：1920x1080
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
    // 竖屏常用（仍是官方格式）
    '1080x1920',
    '1440x2560',
    '2160x3840',
  ];

  // 最小分辨率 atleast（单选）
  static const List<String> _atleastOptions = [
    '', // 不限
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

  // 常用比例（参数格式：16x9）
  static const List<String> _ratioOptions = [
    '16x9',
    '16x10',
    '21x9',
    '32x9',
    '4x3',
    '3x2',
    '5x4',
    '1x1',
    // 竖屏常用
    '9x16',
    '10x16',
  ];

  // 颜色（单选，参数格式：RRGGBB，不带 #）
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
    // 常用色（仍只显示为灰阶文本 chip，不搞花色 UI）
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
    _qCtrl.dispose();
    super.dispose();
  }

  Color _monoPrimary(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark ? Colors.white : Colors.black;
  }

  TextStyle _titleStyle(BuildContext context) {
    final theme = Theme.of(context);
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: theme.textTheme.bodyLarge?.color,
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _titleStyle(context)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // =========================
  // 折叠卡片：全局卡片样式 + 全局圆角
  // =========================
  Widget _collapseCard({
    required BuildContext context,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget expandedChild,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final tokens = theme.extension<AppTokens>()!;
    final r = ThemeScope.of(context).cardRadius;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: mono.withOpacity(0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0,
                    duration: tokens.expandDuration,
                    curve: tokens.expandCurve,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: mono.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: expandedChild,
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: tokens.expandDuration,
            firstCurve: tokens.expandCurve,
            secondCurve: tokens.expandCurve,
          ),
        ],
      ),
    );
  }

  // 单选折叠：展开后列表 + 当前对号
  Widget _collapseSinglePick({
    required BuildContext context,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required List<_PickItem<String>> items,
    required String value,
    required ValueChanged<String> onPick,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    Widget optionRow(_PickItem<String> it, bool isLast) {
      final selected = it.value == value;
      return InkWell(
        onTap: () => onPick(it.value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: isLast ? BorderSide.none : BorderSide(color: mono.withOpacity(0.10), width: 1),
            ),
          ),
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
      );
    }

    return _collapseCard(
      context: context,
      valueLabel: valueLabel,
      expanded: expanded,
      onToggle: onToggle,
      expandedChild: Column(
        children: List.generate(items.length, (i) {
          final it = items[i];
          final isLast = i == items.length - 1;
          return optionRow(it, isLast);
        }),
      ),
    );
  }

  // 多选折叠：用 chip（参数是逗号分隔）
  Widget _collapseMultiPickChips({
    required BuildContext context,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<Set<String>> onChanged,
    String emptyHint = '不限',
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final tokens = theme.extension<AppTokens>()!;
    final innerR = tokens.smallRadius;

    Widget chip(String text, bool isOn) {
      return InkWell(
        onTap: () {
          final next = Set<String>.from(selected);
          if (isOn) {
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
            color: isOn ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              width: 1,
              color: isOn ? mono.withOpacity(0.40) : mono.withOpacity(0.12),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isOn ? mono : theme.textTheme.bodyLarge?.color,
              fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return _collapseCard(
      context: context,
      valueLabel: valueLabel.isEmpty ? emptyHint : valueLabel,
      expanded: expanded,
      onToggle: onToggle,
      expandedChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: mono.withOpacity(0.10), width: 1)),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(innerR),
            bottomRight: Radius.circular(innerR),
          ),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) => chip(o, selected.contains(o))).toList(),
        ),
      ),
    );
  }

  // 多选折叠：checkbox 列表（分类 / 分级）
  Widget _collapseMultiCheck({
    required BuildContext context,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required List<_CheckItem> items,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final tokens = theme.extension<AppTokens>()!;
    final innerR = tokens.smallRadius;

    Widget row(_CheckItem it, bool isLast) {
      final selected = it.value;
      return InkWell(
        onTap: () => it.onChanged(!selected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              bottom: isLast ? BorderSide.none : BorderSide(color: mono.withOpacity(0.10), width: 1),
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
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
              if (selected) Icon(Icons.check, size: 18, color: mono),
            ],
          ),
        ),
      );
    }

    return _collapseCard(
      context: context,
      valueLabel: valueLabel,
      expanded: expanded,
      onToggle: onToggle,
      expandedChild: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: mono.withOpacity(0.10), width: 1)),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(innerR),
            bottomRight: Radius.circular(innerR),
          ),
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final isLast = i == items.length - 1;
            return row(items[i], isLast);
          }),
        ),
      ),
    );
  }

  // 单行输入折叠（用于你还想保留输入能力时）
  Widget _collapseInput({
    required BuildContext context,
    required String valueLabel,
    required bool expanded,
    required VoidCallback onToggle,
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final tokens = theme.extension<AppTokens>()!;
    final innerR = tokens.smallRadius;

    final ctrl = TextEditingController(text: value);

    return _collapseCard(
      context: context,
      valueLabel: valueLabel,
      expanded: expanded,
      onToggle: onToggle,
      expandedChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: mono.withOpacity(0.10), width: 1)),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(innerR),
            bottomRight: Radius.circular(innerR),
          ),
        ),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: mono.withOpacity(0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: mono.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: mono.withOpacity(0.35)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ====== bits / helpers ======

  String _catBit(String old, int index, bool on) {
    final chars = old.padRight(3, '1').split('');
    if (index >= 0 && index < 3) chars[index] = on ? '1' : '0';
    return chars.take(3).join();
  }

  String _purityBit(String old, int index, bool on) {
    final chars = old.padRight(3, '0').split('');
    if (index >= 0 && index < 3) chars[index] = on ? '1' : '0';
    return chars.take(3).join();
  }

  String _labelFromPick(List<_PickItem<String>> items, String value, {String fallback = '-'}) {
    for (final it in items) {
      if (it.value == value) return it.label;
    }
    return fallback;
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

  String _summaryCsv(String csv, {String empty = '不限'}) {
    final set = _csvToSet(csv);
    if (set.isEmpty) return empty;
    final list = set.toList()..sort();
    if (list.length <= 2) return list.join('，');
    return '${list.take(2).join('，')} 等 ${list.length} 项';
    // 不搞长串，保持克制
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
    final tokens = theme.extension<AppTokens>()!;

    // 全局卡片圆角来自 ThemeStore（滑条）
    // 这里不需要额外引用 cardRadius 变量，每个折叠卡片内部都会取 ThemeScope.cardRadius

    // resolutions / ratios 多选
    final selectedRes = _csvToSet(_f.resolutions);
    final selectedRatios = _csvToSet(_f.ratios);

    return SafeArea(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: Padding(
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
                      Navigator.of(context).maybePop();
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
                    // 关键词（也做折叠：收起时不占空间）
                    _section(
                      context,
                      "关键词",
                      _collapseInput(
                        context: context,
                        valueLabel: _qCtrl.text.trim().isEmpty ? '不限' : _qCtrl.text.trim(),
                        expanded: true, // 关键词保持常开更顺手，你要也可改成状态变量
                        onToggle: () {},
                        value: _qCtrl.text,
                        hint: "输入关键字（留空为不限）",
                        onChanged: (v) => setState(() {
                          _qCtrl.text = v;
                          _qCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _qCtrl.text.length));
                          _f = _f.copyWith(query: v);
                        }),
                      ),
                    ),

                    // 排序方式：折叠单选
                    _section(
                      context,
                      "排序方式",
                      _collapseSinglePick(
                        context: context,
                        valueLabel: _labelFromPick(_sortingItems, _f.sorting, fallback: _f.sorting),
                        expanded: _sortingExpanded,
                        onToggle: () => setState(() => _sortingExpanded = !_sortingExpanded),
                        items: _sortingItems,
                        value: _f.sorting,
                        onPick: (v) {
                          setState(() {
                            _f = _f.copyWith(sorting: v);
                            _sortingExpanded = false;
                            // 切换排序时，如果不在 toplist，就收起榜单时间范围
                            if (v != 'toplist') _topRangeExpanded = false;
                          });
                        },
                      ),
                    ),

                    // 榜单时间范围：折叠单选（仅 toplist 显示）
                    if (_f.sorting == 'toplist')
                      _section(
                        context,
                        "榜单时间范围",
                        _collapseSinglePick(
                          context: context,
                          valueLabel: _labelFromPick(_topRangeItems, _f.topRange, fallback: _f.topRange),
                          expanded: _topRangeExpanded,
                          onToggle: () => setState(() => _topRangeExpanded = !_topRangeExpanded),
                          items: _topRangeItems,
                          value: _f.topRange,
                          onPick: (v) {
                            setState(() {
                              _f = _f.copyWith(topRange: v);
                              _topRangeExpanded = false;
                            });
                          },
                        ),
                      ),

                    // 排序方向：折叠单选
                    _section(
                      context,
                      "排序方向",
                      _collapseSinglePick(
                        context: context,
                        valueLabel: _labelFromPick(_orderItems, _f.order, fallback: _f.order),
                        expanded: _orderExpanded,
                        onToggle: () => setState(() => _orderExpanded = !_orderExpanded),
                        items: _orderItems,
                        value: _f.order,
                        onPick: (v) {
                          setState(() {
                            _f = _f.copyWith(order: v);
                            _orderExpanded = false;
                          });
                        },
                      ),
                    ),

                    // 分类：折叠多选（checkbox）
                    _section(
                      context,
                      "分类",
                      _collapseMultiCheck(
                        context: context,
                        valueLabel: _summaryCategories(),
                        expanded: _categoriesExpanded,
                        onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
                        items: [
                          _CheckItem(
                            label: '常规',
                            value: _f.categories.length > 0 ? _f.categories[0] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(categories: _catBit(_f.categories, 0, v))),
                          ),
                          _CheckItem(
                            label: '动漫',
                            value: _f.categories.length > 1 ? _f.categories[1] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(categories: _catBit(_f.categories, 1, v))),
                          ),
                          _CheckItem(
                            label: '人物',
                            value: _f.categories.length > 2 ? _f.categories[2] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(categories: _catBit(_f.categories, 2, v))),
                          ),
                        ],
                      ),
                    ),

                    // 分级（purity）：折叠多选
                    _section(
                      context,
                      "分级",
                      _collapseMultiCheck(
                        context: context,
                        valueLabel: _summaryPurity(),
                        expanded: _purityExpanded,
                        onToggle: () => setState(() => _purityExpanded = !_purityExpanded),
                        items: [
                          _CheckItem(
                            label: 'SFW',
                            value: _f.purity.length > 0 ? _f.purity[0] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(purity: _purityBit(_f.purity, 0, v))),
                          ),
                          _CheckItem(
                            label: 'Sketchy',
                            value: _f.purity.length > 1 ? _f.purity[1] == '1' : false,
                            onChanged: (v) => setState(() => _f = _f.copyWith(purity: _purityBit(_f.purity, 1, v))),
                          ),
                          _CheckItem(
                            label: 'NSFW',
                            value: _f.purity.length > 2 ? _f.purity[2] == '1' : false,
                            onChanged: (v) => setState(() => _f = _f.copyWith(purity: _purityBit(_f.purity, 2, v))),
                          ),
                        ],
                      ),
                    ),

                    // 分辨率 resolutions：折叠多选 chips（逗号分隔）
                    _section(
                      context,
                      "分辨率（精确匹配）",
                      _collapseMultiPickChips(
                        context: context,
                        valueLabel: _summaryCsv(_f.resolutions),
                        expanded: _resolutionsExpanded,
                        onToggle: () => setState(() => _resolutionsExpanded = !_resolutionsExpanded),
                        options: _resolutionOptions,
                        selected: selectedRes,
                        onChanged: (set) => setState(() => _f = _f.copyWith(resolutions: _setToCsv(set))),
                      ),
                    ),

                    // 最小分辨率 atleast：折叠单选（含不限）
                    _section(
                      context,
                      "最小分辨率（至少）",
                      _collapseSinglePick(
                        context: context,
                        valueLabel: _summaryAtleast(),
                        expanded: _atleastExpanded,
                        onToggle: () => setState(() => _atleastExpanded = !_atleastExpanded),
                        items: _atleastOptions.map((v) {
                          if (v.isEmpty) return const _PickItem('', '不限');
                          return _PickItem(v, v);
                        }).toList(),
                        value: _f.atleast.trim(),
                        onPick: (v) {
                          setState(() {
                            _f = _f.copyWith(atleast: v.trim());
                            _atleastExpanded = false;
                          });
                        },
                      ),
                    ),

                    // 比例 ratios：折叠多选 chips（逗号分隔）
                    _section(
                      context,
                      "比例",
                      _collapseMultiPickChips(
                        context: context,
                        valueLabel: _summaryCsv(_f.ratios),
                        expanded: _ratiosExpanded,
                        onToggle: () => setState(() => _ratiosExpanded = !_ratiosExpanded),
                        options: _ratioOptions,
                        selected: selectedRatios,
                        onChanged: (set) => setState(() => _f = _f.copyWith(ratios: _setToCsv(set))),
                      ),
                    ),

                    // 颜色 colors：折叠单选（RRGGBB）
                    _section(
                      context,
                      "颜色（十六进制）",
                      _collapseSinglePick(
                        context: context,
                        valueLabel: _summaryColor(),
                        expanded: _colorsExpanded,
                        onToggle: () => setState(() => _colorsExpanded = !_colorsExpanded),
                        items: [
                          const _PickItem('', '不限'),
                          ..._colorOptions.map((c) => _PickItem(c, c.toUpperCase())),
                        ],
                        value: _f.colors.trim().replaceAll('#', ''),
                        onPick: (v) {
                          setState(() {
                            _f = _f.copyWith(colors: v.trim().replaceAll('#', ''));
                            _colorsExpanded = false;
                          });
                        },
                      ),
                    ),

                    // 如果你还想保留“手动输入颜色”，可以把下面这段打开（但仍是折叠、黑白灰 UI）
                    // _section(
                    //   context,
                    //   "颜色（手动输入）",
                    //   _collapseInput(
                    //     context: context,
                    //     valueLabel: _summaryColor(),
                    //     expanded: false,
                    //     onToggle: () => setState(() => _colorsExpanded = !_colorsExpanded),
                    //     value: _f.colors,
                    //     hint: "例如 660000（留空为不限，不要带 #）",
                    //     onChanged: (v) => setState(() => _f = _f.copyWith(colors: v.trim().replaceAll('#', ''))),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mono,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    widget.onApply(_f.copyWith(query: _qCtrl.text));
                    Navigator.of(context).maybePop();
                  },
                  child: const Text("应用筛选"),
                ),
              ),
            ],
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