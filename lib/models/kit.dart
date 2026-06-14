class Kit {
  final int? id;
  final String name;
  final String? imageUrl;
  final List<String> productNames;

  const Kit({
    this.id,
    required this.name,
    this.imageUrl,
    this.productNames = const [],
  });

  factory Kit.fromJson(Map<String, dynamic> json) {
    return Kit(
      id: json['id'] as int?,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}
