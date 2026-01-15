// lib/domain/entities/detail_field.dart

enum DetailFieldType {
  text,
  url,
  number,
  bytes,
}

class DetailField {
  final String key;
  final String label;
  final DetailFieldType type;

  /// 原始值：String / int / double 等都行
  final dynamic raw;

  const DetailField({
    required this.key,
    required this.label,
    required this.type,
    required this.raw,
  });

  // ---------- factories ----------
  factory DetailField.text({
    required String key,
    required String label,
    required String value,
  }) {
    return DetailField(key: key, label: label, type: DetailFieldType.text, raw: value);
  }

  factory DetailField.url({
    required String key,
    required String label,
    required String value,
  }) {
    return DetailField(key: key, label: label, type: DetailFieldType.url, raw: value);
  }

  factory DetailField.number({
    required String key,
    required String label,
    required num value,
  }) {
    return DetailField(key: key, label: label, type: DetailFieldType.number, raw: value);
  }

  factory DetailField.bytes({
    required String key,
    required String label,
    required int value,
  }) {
    return DetailField(key: key, label: label, type: DetailFieldType.bytes, raw: value);
  }

  // ---------- display ----------
  String get displayValue {
    switch (type) {
      case DetailFieldType.bytes:
        return _humanBytes(_asInt(raw));
      case DetailFieldType.number:
        return _asNum(raw)?.toString() ?? _asString(raw);
      case DetailFieldType.url:
      case DetailFieldType.text:
        return _asString(raw);
    }
  }

  String get copyValue => displayValue;

  static String _asString(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v?.toString().trim() ?? '';
    return int.tryParse(s) ?? 0;
  }

  static num? _asNum(dynamic v) {
    if (v is num) return v;
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }

  static String _humanBytes(int bytes) {
    if (bytes <= 0) return "-";
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;
    final b = bytes.toDouble();
    if (b >= gb) return "${(b / gb).toStringAsFixed(2)} GB";
    if (b >= mb) return "${(b / mb).toStringAsFixed(2)} MB";
    if (b >= kb) return "${(b / kb).toStringAsFixed(2)} KB";
    return "$bytes B";
  }
}