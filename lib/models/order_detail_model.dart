// file: lib/models/order_detail_model.dart
import 'package:intl/intl.dart'; // Cho việc format ngày tháng và tiền tệ

import 'order_item_model.dart';
import 'shipping_address_model.dart';
 // Model cho địa chỉ giao hàng

class OrderDetailModel {
  final int orderId;
  final String? userEmail;
  final String? userName; // Tên người đặt hàng
  final String? userPhone; // SĐT người đặt hàng
  final DateTime? orderDate; // Sẽ dùng createdAt từ backend làm ngày đặt hàng
  final String status;
  final ShippingAddressModel? shippingAddress; // Thông tin địa chỉ giao hàng
  final String paymentMethod;
  final List<OrderItemModel> items; // Danh sách các sản phẩm trong đơn
  final double? subtotalAmount; // Tổng tiền hàng (trước voucher, trước ship)
  final double? shippingFee;
  final String? appliedVoucherCode; // Mã voucher đã áp dụng (nếu có)
  final double? voucherDiscountAmount; // Số tiền được giảm bởi voucher (nếu có)
  final double? totalAmount; // Tổng tiền cuối cùng
  final String? adminCancelReason; // Lý do admin hủy (nếu có)
  final String? userCancelReason;  // Lý do user hủy (nếu có)
  final DateTime? createdAt; // Thời điểm bản ghi Order được tạo (dùng làm ngày đặt hàng)
  final DateTime? updatedAt; // Thời điểm bản ghi Order được cập nhật

  OrderDetailModel({
    required this.orderId,
    this.userEmail,
    this.userName,
    this.userPhone,
    this.orderDate, // Sẽ được gán từ createdAt
    required this.status,
    this.shippingAddress,
    required this.paymentMethod,
    required this.items,
    this.subtotalAmount,
    this.shippingFee,
    this.appliedVoucherCode,
    this.voucherDiscountAmount,
    this.totalAmount,
    this.adminCancelReason,
    this.userCancelReason,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    // Helper an toàn để parse
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    DateTime? _parseDateTime(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print("Error parsing date: $dateString - $e");
        return null;
      }
    }

    List<OrderItemModel> parsedItems = [];
    if (json['items'] != null && json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((itemData) => OrderItemModel.fromJson(itemData as Map<String, dynamic>))
      // .whereType<OrderItemModel>() // Nếu OrderItemModel.fromJson có thể trả về null
          .toList();
    }

    ShippingAddressModel? parsedShippingAddress;
    if (json['shippingAddress'] != null && json['shippingAddress'] is Map) {
      parsedShippingAddress = ShippingAddressModel.fromJson(json['shippingAddress'] as Map<String, dynamic>);
    }

    // Sử dụng createdAt cho orderDate nếu orderDate trong JSON là null hoặc không có
    DateTime? effectiveOrderDate = _parseDateTime(json['createdAt'] as String?);
    if (json['orderDate'] != null) { // Ưu tiên orderDate từ JSON nếu có
      effectiveOrderDate = _parseDateTime(json['orderDate'] as String?) ?? effectiveOrderDate;
    }


    return OrderDetailModel(
      orderId: _parseInt(json['orderId']) ?? 0, // Cần ID, nếu null thì là lỗi dữ liệu
      userEmail: json['userEmail'] as String?,
      userName: json['userName'] as String?,
      userPhone: json['userPhone'] as String?,
      orderDate: effectiveOrderDate, // Ngày đặt hàng
      status: json['status'] as String? ?? 'UNKNOWN',
      shippingAddress: parsedShippingAddress,
      paymentMethod: json['paymentMethod'] as String? ?? 'N/A',
      items: parsedItems,
      subtotalAmount: _parseDouble(json['subtotalAmount']),
      shippingFee: _parseDouble(json['shippingFee']),
      appliedVoucherCode: json['appliedVoucherCode'] as String?,
      voucherDiscountAmount: _parseDouble(json['voucherDiscountAmount']),
      totalAmount: _parseDouble(json['totalAmount']),
      adminCancelReason: json['adminCancelReason'] as String?,
      userCancelReason: json['userCancelReason'] as String?,
      createdAt: _parseDateTime(json['createdAt'] as String?), // Thời điểm tạo bản ghi
      updatedAt: _parseDateTime(json['updatedAt'] as String?),
    );
  }

  // Getter tiện lợi để hiển thị ngày tháng
  String get formattedOrderDate {
    if (orderDate == null) return "N/A";
    return DateFormat('dd/MM/yyyy HH:mm').format(orderDate!);
  }

  String get formattedCreatedAt {
    if (createdAt == null) return "N/A";
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt!);
  }

  String get formattedUpdatedAt {
    if (updatedAt == null) return "N/A";
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt!);
  }
}