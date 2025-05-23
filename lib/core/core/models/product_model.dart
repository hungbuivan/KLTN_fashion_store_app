class Product {
  final int id;
  final String name;
  final String imageUrl;
  final double price;
  final int stock;
  final String description;

  Product({required this.id, required this.name, required this.imageUrl, required this.price, required this.stock, required this.description});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'] ?? '', // Nếu không có ảnh, để chuỗi rỗng
      price: json['price'].toDouble(),
      stock: json['stock'],
      description: json['description'],
    );
  }
}
