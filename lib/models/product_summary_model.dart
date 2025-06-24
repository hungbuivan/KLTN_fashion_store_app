// file: lib/models/product_summary_model.dart

class ProductSummaryModel {
  final int id;
  final String name;
  final double? price;
  final String? imageUrl;
  final bool? isFavorite;

  ProductSummaryModel({
    required this.id,
    required this.name,
    this.price,
    this.imageUrl,
    this.isFavorite,
  });

  factory ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProductSummaryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Không có tên',
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'],
      isFavorite: json['isFavorite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }
}

