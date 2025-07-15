// file: lib/providers/voucher_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/voucher_model.dart'; // Model Voucher
import '../dto/voucher_check_response_dto.dart'; // DTO cho kết quả kiểm tra voucher
import 'auth_provider.dart'; // Để lấy userId

class VoucherProvider with ChangeNotifier {
  final AuthProvider authProvider;

  // URL cơ sở cho API, trỏ đến backend của bạn
  final String _baseApiUrl = 'http://10.0.2.2:8080/api';

  List<VoucherModel> _applicableVouchers = [];
  List<VoucherModel> get applicableVouchers => _applicableVouchers;

  VoucherCheckResponse? _checkedVoucherInfo;
  VoucherCheckResponse? get checkedVoucherInfo => _checkedVoucherInfo;

  String? _appliedVoucherCode;
  String? get appliedVoucherCode => _appliedVoucherCode;

  double _currentDiscountAmount = 0.0;
  double get currentDiscountAmount => _currentDiscountAmount;

  bool _isLoadingApplicableVouchers = false;
  bool get isLoadingApplicableVouchers => _isLoadingApplicableVouchers;

  bool _isLoadingCheckVoucher = false;
  bool get isLoadingCheckVoucher => _isLoadingCheckVoucher;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VoucherProvider(this.authProvider);

  void _clearError() {
    _errorMessage = null;
  }

  void _clearCheckedVoucherState() {
    _checkedVoucherInfo = null;
    _appliedVoucherCode = null;
    _currentDiscountAmount = 0.0;
  }

  // Lấy danh sách các voucher khả dụng
  Future<void> fetchApplicableVouchers(double orderSubtotal) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _applicableVouchers = [];
      notifyListeners();
      return;
    }
    final int userId = authProvider.user!.id; // Giả sử User.id là int

    _isLoadingApplicableVouchers = true;
    _clearError();
    notifyListeners();

    try {
      final queryParams = {
        'userId': userId.toString(),
        'orderSubtotal': orderSubtotal.toString(),
      };
      final url = Uri.parse('$_baseApiUrl/vouchers/applicable').replace(queryParameters: queryParams);

      print("VoucherProvider: Fetching applicable vouchers from $url");
      final response = await http.get(url /*, headers: await _getAuthHeaders()*/); // Bỏ comment headers nếu API cần token

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        final List<VoucherModel?> tempList = decodedData
            .map((json) => VoucherModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _applicableVouchers = tempList.whereType<VoucherModel>().toList();
        _errorMessage = null;
        print("VoucherProvider: Fetched ${_applicableVouchers.length} applicable vouchers.");
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        _errorMessage = "Lỗi tải mã giảm giá: ${response.statusCode} - $responseBody";
        _applicableVouchers = [];
        print("VoucherProvider: Error fetching applicable vouchers - ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tải mã giảm giá: ${e.toString()}";
      _applicableVouchers = [];
      print("VoucherProvider: Error fetching applicable vouchers: $e");
    }
    _isLoadingApplicableVouchers = false;
    notifyListeners();
  }

  // Kiểm tra và áp dụng một mã voucher cụ thể
  Future<bool> checkAndApplyVoucher(String voucherCodeInput, double orderSubtotal) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để sử dụng mã giảm giá.";
      removeAppliedVoucher(); // Xóa voucher cũ nếu có và notify
      return false;
    }

    final String voucherCode = voucherCodeInput.trim().toUpperCase();
    if (voucherCode.isEmpty) {
      _errorMessage = "Vui lòng nhập mã giảm giá.";
      removeAppliedVoucher();
      return false;
    }

    final int userId = authProvider.user!.id;

    _isLoadingCheckVoucher = true;
    _clearError();
    // Không xóa _appliedVoucherCode và _currentDiscountAmount ngay, chỉ xóa nếu check thất bại
    notifyListeners();

    bool appliedSuccessfully = false;
    try {
      // API: POST /api/orders/check-voucher
      // Backend của bạn nhận userId qua Query Parameter cho API này
      final url = Uri.parse('$_baseApiUrl/orders/check-voucher?userId=${userId.toString()}');
      print("VoucherProvider: Checking voucher '$voucherCode' at $url for user $userId with subtotal $orderSubtotal");

      final Map<String, dynamic> requestBody = {
        'voucherCode': voucherCode,
        'orderSubtotal': orderSubtotal,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8' /*, ...await _getAuthHeaders()*/},
        body: jsonEncode(requestBody),
      );

      final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
      print("VoucherProvider: Check voucher response status: ${response.statusCode}");
      print("VoucherProvider: Check voucher response body: $responseData");

      _checkedVoucherInfo = VoucherCheckResponse.fromJson(responseData);

      if (response.statusCode == 200 && _checkedVoucherInfo!.isValid) {
        _errorMessage = _checkedVoucherInfo!.message; // Thông báo thành công
        _appliedVoucherCode = _checkedVoucherInfo!.voucherCode;
        _currentDiscountAmount = _checkedVoucherInfo!.discountApplied ?? 0.0;
        appliedSuccessfully = true;
      } else {
        _errorMessage = _checkedVoucherInfo?.message ?? "Mã giảm giá không hợp lệ hoặc có lỗi.";
        removeAppliedVoucher(); // Xóa voucher nếu áp dụng không thành công
        appliedSuccessfully = false;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi kiểm tra mã: ${e.toString()}";
      removeAppliedVoucher();
      print("VoucherProvider: Error checking voucher: $e");
      appliedSuccessfully = false;
    }

    _isLoadingCheckVoucher = false;
    notifyListeners();
    return appliedSuccessfully;
  }

  // Xóa voucher đang được áp dụng
  void removeAppliedVoucher() {
    if (_appliedVoucherCode != null || _currentDiscountAmount != 0.0 || _checkedVoucherInfo != null) {
      _clearCheckedVoucherState();
      _errorMessage = null; // Xóa thông báo lỗi cũ liên quan đến voucher
      notifyListeners();
    }
  }

  // Reset state khi user logout hoặc rời khỏi trang checkout
  void resetVoucherState() {
    _applicableVouchers = [];
    _clearCheckedVoucherState();
    _isLoadingApplicableVouchers = false;
    _isLoadingCheckVoucher = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Được gọi bởi ChangeNotifierProxyProvider
  void updateAuthProvider(AuthProvider newAuth) {
    bool wasAuthenticated = authProvider.isAuthenticated;
    bool isAuthenticatedNow = newAuth.isAuthenticated;

    if (wasAuthenticated != isAuthenticatedNow) {
      if (!isAuthenticatedNow) { // User logged out
        print("VoucherProvider: User logged out, resetting voucher state.");
        resetVoucherState();
      } else { // User logged in
        print("VoucherProvider: User logged in, applicable vouchers might be fetched by UI if needed.");
        // Không tự động fetch ở đây, để UI (CheckoutScreen) quyết định khi nào fetch
        // dựa trên orderSubtotal.
      }
    } else if (isAuthenticatedNow && newAuth.user?.id != authProvider.user?.id) {
      // User changed (ví dụ: login tài khoản khác)
      print("VoucherProvider: User changed, resetting voucher state.");
      resetVoucherState();
    }
  }

}