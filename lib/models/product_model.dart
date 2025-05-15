class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final bool? isFavorite; // Nếu có
  final bool? isPopular;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isFavorite,
    required this.isPopular,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'] ?? "",
      isFavorite: json['isFavorite'] as bool?,
      isPopular: json['isPopular'] as bool?,
    );
  }
}
