// lib/pages/wallhaven_filter_sheet.dart
import 'package:flutter/material.dart';

/// ✅ Deprecated: 已被新的通用 FilterDrawer 架构替代。
/// 这个文件仅作为“占位兼容”存在，避免旧引用导致编译失败。
///
/// 下一步：在全仓库删除所有对 WallhavenFilterSheet 的引用后，
/// 你可以直接删除整个文件。
@Deprecated('Replaced by FilterDrawer. Remove all usages and delete this file.')
class WallhavenFilterSheet extends StatelessWidget {
  const WallhavenFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // 旧版专用筛选 UI 已冻结并弃用：不再提供任何交互逻辑
    // （避免继续引入 deprecated API / 造成接口不配套）
    return const SizedBox.shrink();
  }
}