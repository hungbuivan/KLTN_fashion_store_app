// file: lib/models/admin/product_admin_model.dart
// Model này ánh xạ với ProductAdminResponse.java từ backend
class ProductAdminModel {
  final int id;
  final String name;
  final String? description;
  final double? price;
  final int? stock;
  final int? categoryId;
  // final String? categoryName; // Có thể thêm nếu backend trả về và bạn muốn hiển thị
  final int? brandId;
  // final String? brandName; // Có thể thêm
  final String? imageUrl;
  final bool? isPopular;
  // final bool? isFavorite; // Xem xét có cần ở đây không
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductAdminModel({
    required this.id,
    required this.name,
    this.description,
    this.price,
    this.stock,
    this.categoryId,
    // this.categoryName,
    this.brandId,
    // this.brandName,
    this.imageUrl,
    this.isPopular,
    // this.isFavorite,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductAdminModel.fromJson(Map<String, dynamic> json) {
    return ProductAdminModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'N/A', // Xử lý null cho name
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      stock: json['stock'] as int?,
      categoryId: json['categoryId'] as int?,
      // categoryName: json['categoryName'] as String?,
      brandId: json['brandId'] as int?,
      // brandName: json['brandName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isPopular: json['isPopular'] as bool?,
      // isFavorite: json['isFavorite'] as bool?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  // Dùng cho việc tạo mới hoặc cập nhật sản phẩm
  // Chỉ bao gồm các trường mà client có thể gửi đi
  Map<String, dynamic> toJsonForUpsert() {
    return {
      // 'id' không được gửi khi tạo, và thường không được thay đổi khi cập nhật qua body
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId, // Sẽ là null nếu không chọn
      'brandId': brandId,     // Sẽ là null nếu không chọn
      'imageUrl': imageUrl,
      'isPopular': isPopular ?? false, // Mặc định là false nếu null
    };
  }
}
    