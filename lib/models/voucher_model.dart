// file: lib/models/voucher_model.dart
import 'package:intl/intl.dart'; // Cho việc format ngày tháng và tiền tệ nếu cần hiển thị

// Enum này nên được định nghĩa ở đây hoặc import từ một file enums chung
enum DiscountTypeModel {
  PERCENTAGE,
  FIXED_AMOUNT,
  UNKNOWN // Giá trị mặc định nếu không parse được
}

class VoucherModel {
  final int? id; // ID của voucher (Integer từ backend)
  final String code; // Mã voucher
  final String? description; // Mô tả
  final DiscountTypeModel discountType; // Loại giảm giá (PERCENTAGE, FIXED_AMOUNT)
  final double discountValue; // Giá trị giảm (số % hoặc số tiền)
  final double? minOrderValue; // Giá trị đơn hàng tối thiểu để áp dụng
  final double? maxDiscountAmount; // Số tiền giảm tối đa (quan trọng cho loại PERCENTAGE)
  final DateTime? startDate; // Ngày bắt đầu hiệu lực
  final DateTime? endDate; // Ngày kết thúc hiệu lực
  final bool isActive; // Voucher có đang hoạt động không
  // Các trường khác bạn có thể muốn thêm từ VoucherDTO backend:
  final int? usageLimitPerVoucher;
   final int? usageLimitPerUser;
   final int currentUsageCount;

  VoucherModel({
    this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    this.maxDiscountAmount,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.usageLimitPerVoucher,
     this.usageLimitPerUser,
     required this.currentUsageCount,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    // Hàm helper để parse DiscountType từ String
    DiscountTypeModel parseDiscountType(String? typeStr) {
      if (typeStr == 'PERCENTAGE') return DiscountTypeModel.PERCENTAGE;
      if (typeStr == 'FIXED_AMOUNT') return DiscountTypeModel.FIXED_AMOUNT;
      print("VoucherModel.fromJson: Unknown discountType '$typeStr', defaulting to UNKNOWN.");
      return DiscountTypeModel.UNKNOWN;
    }

    // Hàm helper để parse số một cách an toàn
    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }


    return VoucherModel(
      id: _parseInt(json['id']), // Backend trả về id là Integer
      code: json['code'] as String? ?? 'NOCODE', // Cần code để hoạt động
      description: json['description'] as String?,
      discountType: parseDiscountType(json['discountType'] as String?),
      discountValue: _parseDouble(json['discountValue']) ?? 0.0, // Giá trị giảm giá
      minOrderValue: _parseDouble(json['minOrderValue']),
      maxDiscountAmount: _parseDouble(json['maxDiscountAmount']),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      // Backend có thể trả về 'active' hoặc 'isActive'. Ưu tiên 'active', fallback về 'isActive'
      isActive: json['active'] as bool? ?? json['isActive'] as bool? ?? false,
       usageLimitPerVoucher: _parseInt(json['usageLimitPerVoucher']),
       usageLimitPerUser: _parseInt(json['usageLimitPerUser']),
       currentUsageCount: _parseInt(json['currentUsageCount']) ?? 0,
    );
  }

  // Helper để hiển thị thông tin giảm giá một cách thân thiện
  String get discountDisplay {
    final NumberFormat currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);
    if (discountType == DiscountTypeModel.PERCENTAGE) {
      String display = 'Giảm ${discountValue.toStringAsFixed(0)}%';
      if (maxDiscountAmount != null && maxDiscountAmount! > 0) {
        display += ' (tối đa ${currencyFormatter.format(maxDiscountAmount)})';
      }
      return display;
    } else if (discountType == DiscountTypeModel.FIXED_AMOUNT) {
      return 'Giảm ${currencyFormatter.format(discountValue)}';
    }
    return 'Khuyến mãi không xác định';
  }

  // Helper để hiển thị thời gian hiệu lực
  String get validityPeriodDisplay {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm'); // Thêm giờ phút
    String start = startDate != null ? formatter.format(startDate!) : 'N/A';
    String end = endDate != null ? formatter.format(endDate!) : 'N/A';
    return 'Từ: $start\nĐến: $end'; // Hiển thị trên 2 dòng cho dễ đọc
  }

  // Helper để hiển thị điều kiện đơn hàng tối thiểu
  String get minOrderConditionDisplay {
    if (minOrderValue != null && minOrderValue! > 0) {
      final NumberFormat currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);
      return 'Đơn tối thiểu: ${currencyFormatter.format(minOrderValue)}';
    }
    return 'Áp dụng cho mọi đơn hàng';
  }

  // Kiểm tra xem voucher có còn hiệu lực không (dựa trên ngày và isActive)
  bool get isValidNow {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false; // Chưa tới ngày bắt đầu
    if (endDate != null && now.isAfter(endDate!)) return false; // Đã quá ngày kết thúc
    return true;
  }
}