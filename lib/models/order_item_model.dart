// file: lib/models/order_item_model.dart

class OrderItemModel {
  final int? productId; // ID của sản phẩm (Integer từ backend)
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double? priceAtPurchase; // Giá của một sản phẩm tại thời điểm mua
  final double? subTotal;        // Thành tiền (quantity * priceAtPurchase)
  final String? color;
  final String? size;
  OrderItemModel({
    this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    this.priceAtPurchase,
    this.subTotal,
    this.color,
    this.size,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    print("🧩 OrderItem JSON: $json"); // 👈 Dòng này để log JSON item

    // Helper an toàn để parse int và double
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt(); // Chấp nhận double từ JSON cho int
      return null;
    }
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderItemModel(
      productId: parseInt(json['productId']),
      productName: json['productName'] as String? ?? 'Sản phẩm không xác định',
      productImageUrl: json['productImageUrl'] as String?,
      quantity: parseInt(json['quantity']) ?? 1, // Mặc định là 1 nếu null
      priceAtPurchase: parseDouble(json['priceAtPurchase']),
      subTotal: parseDouble(json['subTotal']),
      // ✅ Parse dữ liệu từ JSON
      size: json['size'] as String?,
      color: json['color'] as String?,

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
      'color': color,
      'size': size
    };
  }
}