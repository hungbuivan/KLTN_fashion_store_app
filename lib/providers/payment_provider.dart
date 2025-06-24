// file: lib/providers/payment_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';

// Model để lưu trữ thông tin VietQR trả về từ backend
class VietQRResponse {
  final bool success;
  final String message;
  final String? qrData;
  final String? accountNo;
  final String? accountName;
  final String? bankBin; // Thường là mã ngân hàng
  final int? amount;
  final String? orderInfo;

  VietQRResponse({
    required this.success,
    required this.message,
    this.qrData,
    this.accountNo,
    this.accountName,
    this.bankBin,
    this.amount,
    this.orderInfo,
  });

  factory VietQRResponse.fromJson(Map<String, dynamic> json) {
    return VietQRResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Lỗi không xác định.',
      qrData: json['qrData'] as String?,
      accountNo: json['accountNo'] as String?,
      accountName: json['accountName'] as String?,
      bankBin: json['bankBin'] as String?,
      amount: json['amount'] as int?,
      orderInfo: json['orderInfo'] as String?,
    );
  }
}

class PaymentProvider with ChangeNotifier {
  final AuthProvider authProvider;

  final String _baseApiUrl = 'http://10.0.2.2:8080/api/payment';

  // State
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VietQRResponse? _vietQRResponse;
  VietQRResponse? get vietQRResponse => _vietQRResponse;

  PaymentProvider(this.authProvider);

  // Hàm tạo mã VietQR
  Future<bool> initiateVietQRPayment({
    required String orderInfo,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _vietQRResponse = null; // Xóa dữ liệu cũ
    notifyListeners();

    try {
      final url = Uri.parse('$_baseApiUrl/vietqr/create');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'amount': amount.toInt(), // Gửi dưới dạng int/long
          'orderInfo': orderInfo,
        }),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      print("VietQR Create Payment Response: $responseData");

      _vietQRResponse = VietQRResponse.fromJson(responseData as Map<String, dynamic>);

      if (response.statusCode == 200 && _vietQRResponse!.success) {
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _vietQRResponse!.message;
      }

    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tạo mã VietQR: ${e.toString()}";
      print("Error initiating VietQR payment: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}