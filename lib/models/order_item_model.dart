// file: lib/models/order_item_model.dart

class OrderItemModel {
  final int? productId; // ID của sản phẩm (Integer từ backend)
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double? priceAtPurchase; // Giá của một sản phẩm tại thời điểm mua
  final double? subTotal;        // Thành tiền (quantity * priceAtPurchase)

  OrderItemModel({
    this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    this.priceAtPurchase,
    this.subTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Helper an toàn để parse int và double
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt(); // Chấp nhận double từ JSON cho int
      return null;
    }
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderItemModel(
      productId: _parseInt(json['productId']),
      productName: json['productName'] as String? ?? 'Sản phẩm không xác định',
      productImageUrl: json['productImageUrl'] as String?,
      quantity: _parseInt(json['quantity']) ?? 1, // Mặc định là 1 nếu null
      priceAtPurchase: _parseDouble(json['priceAtPurchase']),
      subTotal: _parseDouble(json['subTotal']),
    );
  }

  Map<String, dynamic> toJson() { // Nếu bạn cần gửi lại thông tin này lên server (ít khi cho DTO response)
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
      'subTotal': subTotal,
    };
  }
}