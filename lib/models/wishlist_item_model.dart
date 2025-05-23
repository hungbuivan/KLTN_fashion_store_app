// file: lib/models/wishlist_item_model.dart

class WishlistItemModel {
  final int wishlistItemId; // Sẽ là ID của bản ghi wishlist_items
  final int productId;      // ID của sản phẩm
  final String productName;  // Tên sản phẩm
  final double? productPrice;
  final String? productImageUrl;
  final DateTime? addedAt;

  WishlistItemModel({
    required this.wishlistItemId,
    required this.productId,
    required this.productName,
    this.productPrice,
    this.productImageUrl,
    this.addedAt,
  });

  // Factory constructor để parse JSON từ response của backend
  // Sẽ trả về null nếu dữ liệu sản phẩm thiết yếu bị thiếu hoặc không hợp lệ
  static WishlistItemModel? fromJson(Map<String, dynamic> json) {
    try {
      // Kiểm tra các trường ID quan trọng
      final num? rawWishlistItemId = json['wishlistItemId'] as num?;
      final num? rawProductId = json['productId'] as num?;
      final String? rawProductName = json['productName'] as String?;

      if (rawWishlistItemId == null || rawProductId == null || rawProductName == null || rawProductName.isEmpty) {
        // Nếu ID của wishlist item, ID sản phẩm, hoặc tên sản phẩm bị null/rỗng,
        // coi như item này không hợp lệ để hiển thị.
        print("WishlistItemModel.fromJson: Dữ liệu không hợp lệ, wishlistItemId hoặc productId hoặc productName là null/rỗng. JSON: $json");
        return null; // Trả về null để báo hiệu item không hợp lệ
      }

      final int wishlistItemId = rawWishlistItemId.toInt();
      final int productId = rawProductId.toInt();

      // Các trường khác có thể null
      final double? productPrice = (json['productPrice'] as num?)?.toDouble();
      final String? productImageUrl = json['productImageUrl'] as String?;
      final DateTime? addedAt = json['addedAt'] != null ? DateTime.tryParse(json['addedAt']) : null;

      return WishlistItemModel(
        wishlistItemId: wishlistItemId,
        productId: productId,
        productName: rawProductName, // Đã kiểm tra không null/rỗng
        productPrice: productPrice,
        productImageUrl: productImageUrl,
        addedAt: addedAt,
      );
    } catch (e) {
      print("Lỗi khi parse WishlistItemModel từ JSON: $json - Lỗi: $e");
      return null; // Trả về null nếu có lỗi parse
    }
  }
}
    