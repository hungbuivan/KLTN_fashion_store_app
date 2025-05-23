// file: lib/models/cart_item_model.dart

class CartItemModel {
  final int cartItemId; // ID của CartItem (từ backend là Long, parse sang int)
  final int productId;  // ID của Product (từ backend là Integer)
  final String productName;
  final double? productPrice;
  final String? productImageUrl;
  int quantity; // ✅ Số lượng có thể thay đổi
  final double? itemTotalPrice; // Tổng tiền cho item này
  final DateTime? addedAt;
  final DateTime? updatedAt;

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    this.productPrice,
    this.productImageUrl,
    required this.quantity,
    this.itemTotalPrice,
    this.addedAt,
    this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Hàm helper để parse số một cách an toàn
    int parseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return CartItemModel(
      cartItemId: parseInt(json['cartItemId'], defaultValue: -1), // -1 nếu lỗi
      productId: parseInt(json['productId'], defaultValue: -1),   // -1 nếu lỗi
      productName: json['productName'] as String? ?? 'Sản phẩm không xác định',
      productPrice: parseDouble(json['productPrice']),
      productImageUrl: json['productImageUrl'] as String?,
      quantity: parseInt(json['quantity'], defaultValue: 1), // Mặc định là 1
      itemTotalPrice: parseDouble(json['itemTotalPrice']),
      addedAt: json['addedAt'] != null ? DateTime.tryParse(json['addedAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
