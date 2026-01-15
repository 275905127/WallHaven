class DynamicFilterOption {
  final String label;
  final String value;
  const DynamicFilterOption({required this.label, required this.value});
}

enum DynamicFilterType {
  radio,
}

class DynamicFilter {
  final String title;
  final String paramName;
  final DynamicFilterType type;
  final List<DynamicFilterOption> options;

  const DynamicFilter({
    required this.title,
    required this.paramName,
    required this.type,
    required this.options,
  });
}