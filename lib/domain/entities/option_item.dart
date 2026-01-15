// lib/domain/entities/option_item.dart
class OptionItem {
  final String id;     // 稳定值（给 source 翻译用）
  final String label;  // UI 展示文本（可中文）
  const OptionItem({required this.id, required this.label});
}