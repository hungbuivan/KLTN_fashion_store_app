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
  // ✅ Đổi từ List<String> imageUrls thành String? imageUrl
  final String? imageUrl; // URL hình ảnh chính của sản phẩm

  final double? averageRating;
  final int? totalReviews;
  final List<String> availableColors; // Vẫn giữ nếu sản phẩm có nhiều màu
  final List<String> availableSizes;  // Vẫn giữ nếu sản phẩm có nhiều size
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
    this.imageUrl, // ✅ Cập nhật constructor
    this.averageRating,
    this.totalReviews,
    required this.availableColors,
    required this.availableSizes,
    this.isPopular,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic listJson) {
      if (listJson == null || listJson is! List) return [];
      return List<String>.from(listJson.map((item) => item.toString()));
    }

    // ✅ Xử lý imageUrls từ backend
    // Giả sử backend vẫn có thể trả về một list imageUrls nhưng bạn chỉ muốn lấy cái đầu tiên,
    // hoặc backend đã được sửa để chỉ trả về một String imageUrl.
    String? mainImageUrl;
    if (json['imageUrls'] is List && (json['imageUrls'] as List).isNotEmpty) {
      mainImageUrl = (json['imageUrls'] as List)[0] as String?;
    } else if (json['imageUrl'] is String) { // Nếu backend đã trả về key 'imageUrl' là String
      mainImageUrl = json['imageUrl'] as String?;
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
      imageUrl: mainImageUrl, // ✅ Gán ảnh chính
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int?,
      availableColors: parseStringList(json['availableColors']),
      availableSizes: parseStringList(json['availableSizes']),
      isPopular: json['isPopular'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
