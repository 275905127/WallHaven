// lib/domain/entities/detail_field.dart

class DetailField {
  final String key;
  final String label;

  /// ✅ UI/Source 都用 value 这个名字（别再用 text/data 之类的）
  final String value;

  const DetailField({
    required this.key,
    required this.label,
    required this.value,
  });
}