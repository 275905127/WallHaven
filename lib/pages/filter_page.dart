import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // 分类: General, Anime, People
  final Map<String, bool> _categories = {
    '常规': true,
    '动漫': true,
    '人物': false,
  };

  // 纯净度: SFW, Sketchy, NSFW
  final Map<String, bool> _purity = {
    '安全': true,
    '擦边': false,
    '限制级': false,
  };

  // 排序方式
  String _selectedSort = '最新添加';
  final List<String> _sortOptions = [
    '最新添加', '相关度', '随机', '浏览量', '收藏量', '排行榜'
  ];

  // 排行榜时间范围
  String _selectedTopRange = '1个月';
  final List<String> _topRangeOptions = ['1天', '3天', '1周', '1个月', '3个月', '6个月', '1年'];

  // 分辨率
  String _selectedResolution = '任意';
  final List<String> _resolutions = ['任意', '1920x1080', '2560x1440', '4K+'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text("筛选", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              // 重置逻辑
            },
            child: const Text("重置"),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 第一组：分类与分级
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle("分类 (Categories)"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _categories.keys.map((key) {
                      return FilterChip(
                        label: Text(key),
                        selected: _categories[key]!,
                        onSelected: (bool selected) {
                          setState(() {
                            _categories[key] = selected;
                          });
                        },
                        selectedColor: Colors.blue.withOpacity(0.1),
                        checkmarkColor: Colors.blue,
                        labelStyle: TextStyle(
                          color: _categories[key]! ? Colors.blue : Colors.black87,
                          fontWeight: _categories[key]! ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: _categories[key]! ? Colors.blue : Colors.grey.shade300),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildTitle("分级 (Purity)"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _purity.keys.map((key) {
                      Color activeColor = Colors.blue;
                      if (key == '安全') activeColor = Colors.green;
                      if (key == '擦边') activeColor = Colors.orange;
                      if (key == '限制级') activeColor = Colors.red;

                      return FilterChip(
                        label: Text(key),
                        selected: _purity[key]!,
                        onSelected: (bool selected) {
                          setState(() {
                            _purity[key] = selected;
                          });
                        },
                        selectedColor: activeColor.withOpacity(0.1),
                        checkmarkColor: activeColor,
                        labelStyle: TextStyle(
                          color: _purity[key]! ? activeColor : Colors.black87,
                          fontWeight: _purity[key]! ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: _purity[key]! ? activeColor : Colors.grey.shade300),
                        backgroundColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // 第二组：排序
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle("排序 (Sorting)"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((key) {
                      bool isSelected = _selectedSort == key;
                      return ChoiceChip(
                        label: Text(key),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedSort = key;
                            });
                          }
                        },
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.white,
                        showCheckmark: false, 
                      );
                    }).toList(),
                  ),

                  if (_selectedSort == '排行榜') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    _buildTitle("时间范围"),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _topRangeOptions.map((key) {
                          bool isSelected = _selectedTopRange == key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(key),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                if (selected) setState(() => _selectedTopRange = key);
                              },
                              selectedColor: Colors.black,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              backgroundColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // 第三组：分辨率
             Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildTitle("分辨率 (Resolution)"),
                   const SizedBox(height: 12),
                   Wrap(
                    spacing: 8,
                    children: _resolutions.map((key) {
                      bool isSelected = _selectedResolution == key;
                      return ChoiceChip(
                         label: Text(key),
                         selected: isSelected,
                         onSelected: (val) => setState(() => _selectedResolution = key),
                         selectedColor: Colors.black,
                         labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                         showCheckmark: false,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                         backgroundColor: Colors.white,
                      );
                    }).toList(),
                   )
                ],
              ),
             ),

             const SizedBox(height: 80),
          ],
        ),
      ),
      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: () {
               Navigator.pop(context);
            },
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            label: const Text("应用筛选", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.check),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.bold, 
        color: Colors.grey[600]
      ),
    );
  }
}
