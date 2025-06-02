// file: lib/dto/voucher_check_response_dto.dart

class VoucherCheckResponse {
  final bool isValid;
  final String message;
  final String? voucherCode; // Mã code của voucher đã kiểm tra
  final String? description; // Mô tả voucher (nếu hợp lệ)
  final String? discountType; // Loại giảm giá (nếu hợp lệ)
  final double? discountValue; // Giá trị gốc của voucher (nếu hợp lệ)
  final double? discountApplied; // Số tiền thực tế được giảm cho đơn hàng
  final double? newSubtotalAfterDiscount; // Tổng tiền hàng sau khi trừ voucher

  VoucherCheckResponse({
    required this.isValid,
    required this.message,
    this.voucherCode,
    this.description,
    this.discountType,
    this.discountValue,
    this.discountApplied,
    this.newSubtotalAfterDiscount,
  });

  factory VoucherCheckResponse.fromJson(Map<String, dynamic> json) {
    return VoucherCheckResponse(
      isValid: json['valid'] as bool? ?? json['isValid'] as bool? ?? false, // Backend có thể trả về 'valid' hoặc 'isValid'
      message: json['message'] as String? ?? 'Có lỗi xảy ra.',
      voucherCode: json['voucherCode'] as String?,
      description: json['description'] as String?,
      discountType: json['discountType'] as String?,
      discountValue: (json['discountValue'] as num?)?.toDouble(),
      discountApplied: (json['discountApplied'] as num?)?.toDouble(),
      newSubtotalAfterDiscount: (json['newSubtotalAfterDiscount'] as num?)?.toDouble(),
    );
  }
}