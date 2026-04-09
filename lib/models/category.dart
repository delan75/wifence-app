class CategoryOption {
  const CategoryOption({
    required this.key,
    required this.label,
    required this.description,
    this.exampleDomains = const [],
  });

  final String key;
  final String label;
  final String description;
  final List<String> exampleDomains;

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      key: json['key'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      exampleDomains: (json['example_domains'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}
