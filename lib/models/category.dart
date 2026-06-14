class Category {
  final String name;
  final String description;
  final int count;

  const Category({
    required this.name,
    required this.description,
    this.count = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
