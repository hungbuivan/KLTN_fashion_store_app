// file: lib/models/order_summary_model.dart
import 'package:intl/intl.dart'; // Cho việc format ngày tháng và tiền tệ

class OrderSummaryModel {
  final int orderId;
  final DateTime? orderDate; // Sẽ dùng createdAt từ backend
  final String? firstProductImageUrl; // Ảnh đại diện của sản phẩm đầu tiên
  final String firstProductNameOrItemCount; // Tên SP đầu tiên hoặc "Đơn hàng gồm X sản phẩm"
  final int totalQuantityOfItems; // Tổng số lượng các item trong đơn
  final double? totalAmount; // Tổng tiền cuối cùng của đơn hàng
  final String status;
  final String? customerName; // Tên khách hàng (cho Admin view)
  final String? customerEmail; // Email khách hàng (cho Admin view)
  final String? appliedVoucherCode;
  final double? voucherDiscountAmount;

  OrderSummaryModel({
    required this.orderId,
    this.orderDate,
    this.firstProductImageUrl,
    required this.firstProductNameOrItemCount,
    required this.totalQuantityOfItems,
    this.totalAmount,
    required this.status,
    this.customerName,
    this.customerEmail,
    this.appliedVoucherCode,
    this.voucherDiscountAmount,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
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
        print("Error parsing date in OrderSummaryModel: $dateString - $e");
        return null;
      }
    }

    // Backend có thể trả về 'orderDate' (là createdAt của Order) hoặc chỉ 'createdAt'
    // Ưu tiên 'orderDate' nếu có, nếu không dùng 'createdAt'
    DateTime? effectiveOrderDate = _parseDateTime(json['orderDate'] as String?);
    effectiveOrderDate ??= _parseDateTime(json['createdAt'] as String?);


    return OrderSummaryModel(
      orderId: _parseInt(json['orderId']) ?? 0, // Cần ID, nếu null thì là lỗi dữ liệu
      orderDate: effectiveOrderDate,
      firstProductImageUrl: json['firstProductImageUrl'] as String?,
      firstProductNameOrItemCount: json['firstProductNameOrItemCount'] as String? ?? 'Chi tiết đơn hàng',
      totalQuantityOfItems: _parseInt(json['totalQuantityOfItems']) ?? 0,
      totalAmount: _parseDouble(json['totalAmount']),
      status: json['status'] as String? ?? 'UNKNOWN',
      customerName: json['customerName'] as String?,
      customerEmail: json['customerEmail'] as String?,
      appliedVoucherCode: json['appliedVoucherCode'] as String?,
      voucherDiscountAmount: _parseDouble(json['voucherDiscountAmount']),
    );
  }

  // Getter tiện lợi để hiển thị ngày tháng
  String get formattedOrderDate {
    if (orderDate == null) return "N/A";
    return DateFormat('dd/MM/yyyy HH:mm').format(orderDate!);
  }

  // Getter tiện lợi để hiển thị trạng thái một cách thân thiện (tùy chọn)
  String get displayStatus {
    // Logic map 'status' (PENDING, CONFIRMED, etc.) sang tiếng Việt
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Chờ xác nhận';
      case 'CONFIRMED': return 'Đã xác nhận';
      case 'PROCESSING': return 'Đang xử lý';
      case 'SHIPPED': return 'Đang giao';
      case 'DELIVERED': return 'Đã giao';
      case 'COMPLETED': return 'Hoàn thành';
      case 'CANCELLED_BY_USER': return 'Đã hủy bởi bạn';
      case 'CANCELLED_BY_ADMIN': return 'Đã hủy bởi cửa hàng';
      case 'PAYMENT_FAILED': return 'Thanh toán thất bại';
      default: return status;
    }
  }
}