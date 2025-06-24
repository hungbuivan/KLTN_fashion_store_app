// file: lib/models/admin/product_variant_admin_model.dart

class ProductVariantAdminModel {
  final int id; // ID của variant từ database
  final String? size;
  final String? color;
  final int? stock;
  final double? price;
  final String? imageUrl;

  ProductVariantAdminModel({
    required this.id,
    this.size,
    this.color,
    this.stock,
    this.price,
    this.imageUrl,
  });

  factory ProductVariantAdminModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantAdminModel(
      id: json['id'] as int? ?? 0,
      size: json['size'] as String?,
      color: json['color'] as String?,
      stock: json['stock'] as int?,
      price: (json['price'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}