// file: lib/models/cart_item_model.dart

class CartItemModel {
  final int cartItemId;
  final int productId;
  final String productName;
  final double? productPrice;
  final String? productImageUrl;
  int quantity;
  final double? itemTotalPrice;
  final DateTime? addedAt;
  final DateTime? updatedAt;
  final String? color;
  final String? size;

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
    this.color,
    this.size,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
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
      cartItemId: parseInt(json['cartItemId'], defaultValue: -1),
      productId: parseInt(json['productId'], defaultValue: -1),
      productName: json['productName'] as String? ?? 'Sản phẩm không xác định',
      productPrice: parseDouble(json['productPrice']),
      productImageUrl: json['productImageUrl'] as String?,
      quantity: parseInt(json['quantity'], defaultValue: 1),
      itemTotalPrice: parseDouble(json['itemTotalPrice']),
      addedAt: json['addedAt'] != null ? DateTime.tryParse(json['addedAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      color: json['color'] as String?,
      size: json['size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'productId': productId,
      'productName': productName,
      'productPrice': productPrice,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'itemTotalPrice': itemTotalPrice,
      'addedAt': addedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'color': color,
      'size': size,
    };
  }
}
