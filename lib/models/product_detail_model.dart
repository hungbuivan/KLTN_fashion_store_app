// file: lib/models/product_detail_model.dart

class ProductDetailModel {
  final int id;
  final String name;
  final String? description;
  final double? price;
  final double? originalPrice;
  final int? stock;
  final int? categoryId;
  final String? categoryName;
  final int? brandId;
  final String? brandName;

  // Giữ lại String? imageUrl vì bạn đã sửa theo hướng này
  final List<
      String> imageUrls; // ✅ Sửa từ String? imageUrl thành List<String> imageUrls
  final double? averageRating;
  final int? totalReviews;
  final List<String> availableColors;
  final List<String> availableSizes;
  final bool? isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDetailModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.originalPrice,
    this.stock,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    required this.imageUrls,
    this.averageRating,
    this.totalReviews,
    required this.availableColors,
    required this.availableSizes,
    this.isPopular,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    List<String> _parseStringList(dynamic listJson) {
      if (listJson is List) {
        return List<String>.from(listJson.map((item) => item.toString()));
      }
      return [];
    }

    return ProductDetailModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'N/A',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      stock: json['stock'] as int?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      brandId: json['brandId'] as int?,
      brandName: json['brandName'] as String?,
      imageUrls: _parseStringList(json['imageUrls']),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int?,
      availableColors: _parseStringList(json['availableColors']),
      // ✅ Sửa ở đây
      availableSizes: _parseStringList(json['availableSizes']),
      // ✅ Và ở đây
      isPopular: json['isPopular'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(
          json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(
          json['updatedAt']) : null,
    );
  }
}