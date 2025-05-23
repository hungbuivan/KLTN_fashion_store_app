// file: lib/models/cart_model.dart
import 'cart_item_model.dart'; // Import CartItemModel

class CartModel {
  final List<CartItemModel> items;
  final int totalItems;       // Tổng số lượng các sản phẩm (cộng dồn quantity)
  final int distinctItems;    // Số loại sản phẩm khác nhau
  final double? cartTotalPrice; // Tổng tiền của cả giỏ hàng

  CartModel({
    required this.items,
    required this.totalItems,
    required this.distinctItems,
    this.cartTotalPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    List<CartItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((itemData) => CartItemModel.fromJson(itemData as Map<String, dynamic>))
      // Cân nhắc lọc bỏ item lỗi nếu CartItemModel.fromJson có thể trả về null
      // .whereType<CartItemModel>()
          .toList();
    }

    return CartModel(
      items: parsedItems,
      totalItems: json['totalItems'] as int? ?? 0,
      distinctItems: json['distinctItems'] as int? ?? 0,
      cartTotalPrice: (json['cartTotalPrice'] as num?)?.toDouble(),
    );
  }
}
