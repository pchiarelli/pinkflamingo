class Product {
  final int? id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;

  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? category,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
