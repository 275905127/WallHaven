// lib/domain/entities/detail_field.dart
class DetailField {
  final String key;   // stable id e.g. "views"
  final String label; // UI label e.g. "浏览量"
  final String value; // already formatted
  const DetailField({
    required this.key,
    required this.label,
    required this.value,
  });
}