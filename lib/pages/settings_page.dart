import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../models/source_config.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text("设置", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: textColor),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // === 1. 当前图源卡片 ===
                    _buildCard(
                      context,
                      child: Padding(
                        padding: const EdgeInsets.all(20), 
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(appState.locale.languageCode == 'zh' ? "当前图源" : "Current Source", 
                                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Text(appState.currentSource.name, 
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(appState.currentSource.baseUrl, 
                                    style: TextStyle(fontSize: 10, color: Colors.grey, overflow: TextOverflow.ellipsis), maxLines: 1),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.hub, color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // === 2. 设置项列表卡片 ===
                    _buildCard(
                      context,
                      child: Column(
                        children: [
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "主题" : "Theme",
                            subtitle: _getThemeSubtitle(appState),
                            icon: Icons.palette_outlined,
                            onTap: () => _showThemeDialog(context, appState),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "语言" : "Language",
                            subtitle: appState.locale.languageCode == 'zh' ? "简体中文" : "English",
                            icon: Icons.language,
                            onTap: () => _showLanguageDialog(context, appState),
                          ),
                          _divider(),
                          _buildTile(
                            context,
                            title: appState.locale.languageCode == 'zh' ? "图源管理" : "Source Manager",
                            subtitle: appState.locale.languageCode == 'zh' ? "添加、编辑或删除" : "Manage sources",
                            icon: Icons.source_outlined,
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _showSourceManagerDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _getThemeSubtitle(AppState state) {
    String mode = "跟随系统";
    if (state.themeMode == ThemeMode.light) mode = "浅色";
    if (state.themeMode == ThemeMode.dark) mode = "深色";
    return mode;
  }

  // --- 弹窗逻辑 ---

  // 1. 图源管理
  void _showSourceManagerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, state, child) {
            return _buildBottomDialog(
              context,
              title: "图源管理",
              content: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...List.generate(state.sources.length, (index) {
                      final source = state.sources[index];
                      final isSelected = state.currentSource == source;
                      return ListTile(
                        title: Text(source.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(source.baseUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state.sources.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => _confirmDelete(context, state, index),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                              onPressed: () {
                                Navigator.pop(context); 
                                _showSourceConfigDialog(context, state, existingSource: source, index: index);
                              },
                            ),
                            if (isSelected) 
                              const Icon(Icons.check_circle, color: Colors.blue),
                          ],
                        ),
                        onTap: () {
                          state.setSource(index);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text("添加自定义图源"),
                      onTap: () {
                        Navigator.pop(context);
                        _showSourceConfigDialog(context, state);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text("导入配置"),
                      onTap: () {
                        Navigator.pop(context);
                        _showImportDialog(context, state);
                      },
                    ),
                  ],
                ),
              ),
              onConfirm: () => Navigator.pop(context),
              confirmText: "关闭",
              hideCancel: true,
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AppState state, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: const Text("确定要删除这个图源吗？此操作无法撤销。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              state.removeSource(index);
              Navigator.pop(ctx);
            }, 
            child: const Text("删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSourceConfigDialog(BuildContext context, AppState state, {SourceConfig? existingSource, int? index}) {
    final isEditing = existingSource != null;
    final nameCtrl = TextEditingController(text: existingSource?.name);
    final urlCtrl = TextEditingController(text: existingSource?.baseUrl ?? "https://");
    final apiKeyCtrl = TextEditingController(text: existingSource?.apiKey);
    final listKeyCtrl = TextEditingController(text: existingSource?.listKey ?? "data");
    final thumbKeyCtrl = TextEditingController(text: existingSource?.thumbKey ?? "thumbs.large");
    final fullKeyCtrl = TextEditingController(text: existingSource?.fullKey ?? "path");
    bool showAdvanced = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return _buildBottomDialog(
            context,
            title: isEditing ? "编辑图源" : "添加图源",
            confirmText: "保存",
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInput(nameCtrl, "名称 (Name)"),
                  const SizedBox(height: 10),
                  _buildInput(urlCtrl, "API 地址 (URL)"),
                  const SizedBox(height: 10),
                  _buildInput(apiKeyCtrl, "API Key (可选)"),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => showAdvanced = !showAdvanced),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(showAdvanced ? "收起高级配置" : "展开高级配置"), Icon(showAdvanced ? Icons.expand_less : Icons.expand_more)]
                    ),
                  ),
                  if (showAdvanced) ...[
                     _buildInput(listKeyCtrl, "List Key"),
                     const SizedBox(height: 8),
                     _buildInput(thumbKeyCtrl, "Thumb Key"),
                     const SizedBox(height: 8),
                     _buildInput(fullKeyCtrl, "Full Key"),
                  ]
                ],
              ),
            ),
            onConfirm: () {
              if (nameCtrl.text.isNotEmpty) {
                final newConfig = SourceConfig(
                  name: nameCtrl.text,
                  baseUrl: urlCtrl.text,
                  apiKey: apiKeyCtrl.text,
                  listKey: listKeyCtrl.text,
                  thumbKey: thumbKeyCtrl.text,
                  fullKey: fullKeyCtrl.text,
                  filters: isEditing ? existingSource!.filters : [], 
                );
                if (isEditing) {
                  state.updateSource(index!, newConfig);
                } else {
                  state.addSource(newConfig);
                }
                Navigator.pop(context);
              }
            },
          );
        }
      ),
    );
  }

  // === 3. 外观设置 (重点修改) ===
  void _showThemeDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        ThemeMode tempMode = state.themeMode;
        bool tempMaterialYou = state.useMaterialYou;
        bool tempAmoled = state.useAmoled;
        double tempGlobalRadius = state.cornerRadius;
        double tempHomeRadius = state.homeCornerRadius;

        return StatefulBuilder(
          builder: (context, setState) {
            // ✨ 核心技巧：创建一个动态的形状，绑定到全局圆角
            // 这样 Radio/Switch 的波纹就会完全贴合这个形状
            final dynamicShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tempGlobalRadius),
            );

            return _buildBottomDialog(
              context, title: "外观设置",
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 主题模式选项
                    // 使用 shape: dynamicShape 让波纹圆角实时跟随设置
                    RadioListTile<ThemeMode>(
                      title: const Text("跟随系统"), 
                      value: ThemeMode.system, 
                      groupValue: tempMode, 
                      shape: dynamicShape, 
                      onChanged: (v) => setState(() => tempMode = v!)
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("浅色"), 
                      value: ThemeMode.light, 
                      groupValue: tempMode, 
                      shape: dynamicShape,
                      onChanged: (v) => setState(() => tempMode = v!)
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text("深色"), 
                      value: ThemeMode.dark, 
                      groupValue: tempMode, 
                      shape: dynamicShape,
                      onChanged: (v) => setState(() => tempMode = v!)
                    ),
                    
                    const Divider(height: 24),
                    
                    // 开关选项
                    SwitchListTile(
                      title: const Text("动态取色"), 
                      value: tempMaterialYou, 
                      shape: dynamicShape,
                      onChanged: (v) => setState(() => tempMaterialYou = v)
                    ),
                    SwitchListTile(
                      title: const Text("纯黑背景 (AMOLED)"), 
                      value: tempAmoled, 
                      shape: dynamicShape,
                      onChanged: tempMode == ThemeMode.light ? null : (v) => setState(() => tempAmoled = v)
                    ),
                    
                    const Divider(height: 24),
                    const SizedBox(height: 8),
                    
                    // 🎨 定制滑块：全局圆角
                    _buildFancySlider(
                      context,
                      label: "全局圆角", 
                      value: tempGlobalRadius, 
                      max: 40.0,
                      onChanged: (v) => setState(() => tempGlobalRadius = v)
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 🎨 定制滑块：首页图片
                    _buildFancySlider(
                      context,
                      label: "首页图片", 
                      value: tempHomeRadius, 
                      max: 40.0,
                      onChanged: (v) => setState(() => tempHomeRadius = v)
                    ),
                  ],
                ),
              ),
              onConfirm: () { 
                state.setThemeMode(tempMode); 
                state.setMaterialYou(tempMaterialYou); 
                state.setAmoled(tempAmoled);
                state.setCornerRadius(tempGlobalRadius);
                state.setHomeCornerRadius(tempHomeRadius);
                Navigator.pop(context); 
              }
            );
          },
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = state.locale.languageCode;
        return StatefulBuilder(
          builder: (context, setState) => _buildBottomDialog(
            context, title: "选择语言",
            content: Column(children: [
              RadioListTile<String>(title: const Text("简体中文"), value: 'zh', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
              RadioListTile<String>(title: const Text("English"), value: 'en', groupValue: tempLang, onChanged: (v) => setState(() => tempLang = v!)),
            ]),
            onConfirm: () { state.setLanguage(tempLang); Navigator.pop(context); }
          ),
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => _buildBottomDialog(
      context, title: "导入配置",
      content: TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: "在此粘贴 JSON...")),
      confirmText: "导入",
      onConfirm: () {
        bool success = state.importSourceConfig(controller.text);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "导入成功" : "导入失败"), backgroundColor: success ? Colors.green : Colors.red));
      }
    ));
  }

  // === 组件 ===

  Widget _buildBottomDialog(BuildContext context, {required String title, required Widget content, required VoidCallback onConfirm, String confirmText = "确定", bool hideCancel = false}) {
    // 读取最新的圆角设置，确保外框也同步
    // 注意：如果是外观设置弹窗，这里的 context 读取的是旧值，
    // 但是内容区我们已经手动处理了圆角，所以外框保持 24 或者旧值影响不大，或者也可以传入 tempValue
    return Dialog(
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      shape: Theme.of(context).dialogTheme.shape, // 使用全局形状
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          content,
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            if (!hideCancel) Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.grey, fontSize: 16)))),
            if (!hideCancel) const SizedBox(width: 16),
            Expanded(child: TextButton(onPressed: onConfirm, child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ]),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
    );
  }

  // ✨ 仿制图4的精美滑块样式
  Widget _buildFancySlider(BuildContext context, {required String label, required double value, required double max, required ValueChanged<double> onChanged}) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 40, // 增加高度以容纳大滑块
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 20, // 轨道高度加粗
              // 轨道形状：圆角矩形
              trackShape: const RoundedRectSliderTrackShape(),
              // 激活颜色：主题色
              activeTrackColor: primaryColor,
              // 未激活颜色：淡化
              inactiveTrackColor: primaryColor.withOpacity(0.15),
              // 滑块形状：大白圆，带阴影
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0, elevation: 4.0),
              // 滑块颜色：强制白色
              thumbColor: Colors.white,
              // 点击时的光晕：白色带透明度
              overlayColor: Colors.white.withOpacity(0.3),
              // 刻度点形状：小圆点
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3.5),
              // 激活的刻度点颜色：白色 (在蓝色轨道上显示为白点)
              activeTickMarkColor: Colors.white.withOpacity(0.5),
              // 未激活的刻度点颜色：蓝色 (在浅色轨道上显示为蓝点)
              inactiveTickMarkColor: primaryColor.withOpacity(0.5),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: max,
              divisions: 10, // 分段数，产生刻度点
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) { 
    final radius = context.read<AppState>().cornerRadius; 
    return Card(
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: child 
    ); 
  }

  Widget _buildTile(BuildContext context, {required String title, required String subtitle, required IconData icon, Widget? trailing, VoidCallback? onTap}) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), 
        child: Row(children: [
          Icon(icon, color: textColor.withOpacity(0.7)), 
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)), const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
          ])),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }
  
  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 0, color: Color(0x10000000));
}
