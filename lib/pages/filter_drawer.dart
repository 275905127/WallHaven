// ⚠️ 警示：筛选项必须与 Wallhaven 官方参数 1:1 对应；文案可中文化但参数值不可乱改。
// ⚠️ 警示：UI 风格只允许黑白灰；禁止引入蓝/绿/红等高饱和“装饰色”。

import 'package:flutter/material.dart';

class WallhavenFilters {
  final String query;
  final String sorting; // date_added / relevance / random / views / favorites / toplist
  final String order; // desc / asc
  final String categories; // 111
  final String purity; // 100
  final String resolutions; // "1920x1080" or ""
  final String ratios; // "16x9" or ""
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

  Widget _segmented<T>(
    BuildContext context, {
    required List<_SegItem<T>> items,
    required T value,
    required ValueChanged<T> onChanged,
  }) {
    final mono = _monoPrimary(context);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((it) {
        final selected = it.value == value;
        return GestureDetector(
          onTap: () => onChanged(it.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? mono.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.08) : theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 1,
                color: selected ? mono.withOpacity(0.40) : mono.withOpacity(0.12),
              ),
            ),
            child: Text(
              it.label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? mono : (theme.textTheme.bodyLarge?.color),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

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
                    _section(
                      context,
                      "关键词",
                      TextField(
                        controller: _qCtrl,
                        decoration: InputDecoration(
                          hintText: "输入关键字",
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
                        onChanged: (v) => setState(() => _f = _f.copyWith(query: v)),
                      ),
                    ),

                    _section(
                      context,
                      "排序方式",
                      _segmented<String>(
                        context,
                        items: const [
                          _SegItem('toplist', '榜单'),
                          _SegItem('date_added', '最新'),
                          _SegItem('favorites', '收藏'),
                          _SegItem('views', '浏览'),
                          _SegItem('random', '随机'),
                          _SegItem('relevance', '相关'),
                        ],
                        value: _f.sorting,
                        onChanged: (v) => setState(() => _f = _f.copyWith(sorting: v)),
                      ),
                    ),

                    if (_f.sorting == 'toplist')
                      _section(
                        context,
                        "榜单时间范围",
                        _segmented<String>(
                          context,
                          items: const [
                            _SegItem('1d', '1 天'),
                            _SegItem('3d', '3 天'),
                            _SegItem('1w', '1 周'),
                            _SegItem('1M', '1 月'),
                            _SegItem('3M', '3 月'),
                            _SegItem('6M', '6 月'),
                            _SegItem('1y', '1 年'),
                          ],
                          value: _f.topRange,
                          onChanged: (v) => setState(() => _f = _f.copyWith(topRange: v)),
                        ),
                      ),

                    _section(
                      context,
                      "排序方向",
                      _segmented<String>(
                        context,
                        items: const [
                          _SegItem('desc', '降序'),
                          _SegItem('asc', '升序'),
                        ],
                        value: _f.order,
                        onChanged: (v) => setState(() => _f = _f.copyWith(order: v)),
                      ),
                    ),

                    _section(
                      context,
                      "分类",
                      Column(
                        children: [
                          _checkRow(
                            context,
                            label: "通用",
                            value: _f.categories.length > 0 ? _f.categories[0] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(categories: _catBit(_f.categories, 0, v))),
                          ),
                          _checkRow(
                            context,
                            label: "动漫",
                            value: _f.categories.length > 1 ? _f.categories[1] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(categories: _catBit(_f.categories, 1, v))),
                          ),
                          _checkRow(
                            context,
                            label: "人物",
                            value: _f.categories.length > 2 ? _f.categories[2] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(categories: _catBit(_f.categories, 2, v))),
                          ),
                        ],
                      ),
                    ),

                    _section(
                      context,
                      "纯净度",
                      Column(
                        children: [
                          _checkRow(
                            context,
                            label: "安全 (SFW)",
                            value: _f.purity.length > 0 ? _f.purity[0] == '1' : true,
                            onChanged: (v) => setState(() => _f = _f.copyWith(purity: _purityBit(_f.purity, 0, v))),
                          ),
                          _checkRow(
                            context,
                            label: "擦边 (Sketchy)",
                            value: _f.purity.length > 1 ? _f.purity[1] == '1' : false,
                            onChanged: (v) => setState(() => _f = _f.copyWith(purity: _purityBit(_f.purity, 1, v))),
                          ),
                          _checkRow(
                            context,
                            label: "限制 (NSFW)",
                            value: _f.purity.length > 2 ? _f.purity[2] == '1' : false,
                            onChanged: (v) => setState(() => _f = _f.copyWith(purity: _purityBit(_f.purity, 2, v))),
                          ),
                        ],
                      ),
                    ),

                    _section(
                      context,
                      "分辨率（精确匹配）",
                      _monoInput(
                        context,
                        value: _f.resolutions,
                        hint: "例如 1920x1080（留空为不限）",
                        onChanged: (v) => setState(() => _f = _f.copyWith(resolutions: v.trim())),
                      ),
                    ),

                    _section(
                      context,
                      "最小分辨率（至少）",
                      _monoInput(
                        context,
                        value: _f.atleast,
                        hint: "例如 1920x1080（留空为不限）",
                        onChanged: (v) => setState(() => _f = _f.copyWith(atleast: v.trim())),
                      ),
                    ),

                    _section(
                      context,
                      "比例",
                      _monoInput(
                        context,
                        value: _f.ratios,
                        hint: "例如 16x9（留空为不限）",
                        onChanged: (v) => setState(() => _f = _f.copyWith(ratios: v.trim())),
                      ),
                    ),

                    _section(
                      context,
                      "颜色（十六进制）",
                      _monoInput(
                        context,
                        value: _f.colors,
                        hint: "例如 660000（留空为不限）",
                        onChanged: (v) => setState(() => _f = _f.copyWith(colors: v.trim().replaceAll('#', ''))),
                      ),
                    ),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _monoInput(
    BuildContext context, {
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);
    final ctrl = TextEditingController(text: value);

    return TextField(
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
    );
  }

  Widget _checkRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final mono = _monoPrimary(context);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              checkColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) return mono;
                return mono.withOpacity(0.08);
              }),
              side: BorderSide(color: mono.withOpacity(0.18)),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegItem<T> {
  final T value;
  final String label;
  const _SegItem(this.value, this.label);
}