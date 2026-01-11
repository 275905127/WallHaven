import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // ==========================
  // 筛选状态 (模拟 Wallhaven 参数)
  // ==========================
  
  // 1. Categories (多选) - [General, Anime, People]
  // 对应 Wallhaven 代码 100, 010, 001
  final Map<String, bool> _categories = {
    'General': true,
    'Anime': true,
    'People': false,
  };

  // 2. Purity (多选) - [SFW, Sketchy, NSFW]
  // 注意：NSFW 通常需要 API Key，这里先做 UI
  final Map<String, bool> _purity = {
    'SFW': true,
    'Sketchy': false,
    'NSFW': false,
  };

  // 3. Sorting (单选)
  String _selectedSort = 'Date Added';
  final List<String> _sortOptions = [
    'Date Added', 'Relevance', 'Random', 'Views', 'Favorites', 'Toplist'
  ];

  // 4. Toplist Range (单选 - 只有选 Toplist 时才显示)
  String _selectedTopRange = '1M';
  final List<String> _topRangeOptions = ['1d', '3d', '1w', '1M', '3M', '6M', '1y'];

  // 5. Resolution (单选/多选) - 简化版
  String _selectedResolution = 'Any';
  final List<String> _resolutions = ['Any', '1920x1080', '2560x1440', '4K+'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2), // 全局背景色
      appBar: AppBar(
        title: const Text("筛选", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        centerTitle: false,
        actions: [
          // 重置按钮
          TextButton(
            onPressed: () {
              // 这里写重置逻辑
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("重置筛选")));
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
            // =========================
            // 第一组：基础筛选 (分类 & 等级)
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("分类 (Categories)"),
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
                        // 选中时的颜色配置
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
                  
                  _buildSectionTitle("等级 (Purity)"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _purity.keys.map((key) {
                      Color activeColor = Colors.blue;
                      // Wallhaven 经典色：SFW(绿) Sketchy(黄) NSFW(红)
                      // 但为了保持你的 App 风格统一，我们先用蓝色，或者你可以解开下面的注释
                      if (key == 'SFW') activeColor = Colors.green;
                      if (key == 'Sketchy') activeColor = Colors.orange;
                      if (key == 'NSFW') activeColor = Colors.red;

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

            // =========================
            // 第二组：排序方式
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("排序 (Sorting)"),
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
                        selectedColor: Colors.black, // 选中变黑 (Material 3 风格)
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.white,
                        // 去掉选中时的勾选图标，只变色，更像 iOS/CheckFirm
                        showCheckmark: false, 
                      );
                    }).toList(),
                  ),

                  // 动态显示：只有选了 Toplist 才显示时间范围
                  if (_selectedSort == 'Toplist') ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    _buildSectionTitle("时间范围 (Toplist Range)"),
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
            
            // =========================
            // 第三组：分辨率 & 比例
            // =========================
             Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionTitle("分辨率 (Resolution)"),
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

             // 底部留白，给 FAB 按钮留位置
             const SizedBox(height: 80),
          ],
        ),
      ),
      
      // 底部悬浮确认按钮
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // 宽度占 90%
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: () {
               Navigator.pop(context); // 关闭页面
               // 这里以后可以返回筛选结果
            },
            backgroundColor: Colors.black, // 黑色按钮
            foregroundColor: Colors.white, // 白色文字
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

  // 样式封装：卡片背景
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );
  }

  // 样式封装：小标题
  Widget _buildSectionTitle(String title) {
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
