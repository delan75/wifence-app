class CategoryOption {
  const CategoryOption({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      key: json['key'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
    );
  }
}
