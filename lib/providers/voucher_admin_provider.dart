// file: lib/providers/admin/voucher_admin_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:fashion_store_app/models/common/page_response_model.dart'; // Sử dụng lại PageResponse model
import '../../models/voucher_model.dart';
import '../models/page_response_model.dart'; // Import VoucherModel bạn đã tạo

class VoucherAdminProvider with ChangeNotifier {
  // Base URL cho API quản lý voucher của admin
  final String _baseUrl = 'http://10.0.2.2:8080/api/admin/vouchers';

  PageResponse<VoucherModel>? _pageData;
  PageResponse<VoucherModel>? get pageData => _pageData;

  List<VoucherModel> _vouchers = [];
  List<VoucherModel> get vouchers => _vouchers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Lấy danh sách voucher (phân trang, sắp xếp)
  Future<void> fetchVouchers({
    int page = 0,
    int size = 10,
    String sort = 'endDate,desc', // Mặc định sắp xếp theo ngày hết hạn giảm dần
  }) async {
    _isLoading = true;
    _errorMessage = null;
    if (page == 0) {
      // Chỉ notify nếu là lần tải đầu tiên để hiển thị loading toàn màn hình
      notifyListeners();
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print("VoucherAdminProvider: Fetching vouchers from: $uri");

      // TODO: Thêm headers (ví dụ: token xác thực của admin) nếu API yêu cầu
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _pageData = PageResponse.fromJson(responseData, (json) => VoucherModel.fromJson(json));

        if (page == 0) {
          _vouchers = _pageData!.content; // Thay thế danh sách cũ
        } else {
          _vouchers.addAll(_pageData!.content); // Thêm vào danh sách hiện tại
        }
        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải danh sách voucher: ${response.statusCode} - ${response.body}";
        if (page == 0) _vouchers = [];
        _pageData = null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý: ${e.toString()}";
      if (page == 0) _vouchers = [];
      _pageData = null;
      print("VoucherAdminProvider: Error fetching vouchers: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tạo voucher mới
  Future<VoucherModel?> createVoucher(Map<String, dynamic> voucherData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    VoucherModel? createdVoucher;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'}, // TODO: Thêm auth header
        body: jsonEncode(voucherData),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 201) { // 201 Created
        createdVoucher = VoucherModel.fromJson(responseData);
        await fetchVouchers(page: 0, size: 10, sort: 'id,desc'); // Tải lại trang đầu tiên
      } else {
        _errorMessage = responseData['message'] as String? ?? 'Lỗi tạo voucher.';
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tạo voucher: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
    return createdVoucher;
  }

  // Cập nhật voucher
  Future<VoucherModel?> updateVoucher(int voucherId, Map<String, dynamic> voucherData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    VoucherModel? updatedVoucher;

    try {
      final url = Uri.parse('$_baseUrl/$voucherId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'}, // TODO: Thêm auth header
        body: jsonEncode(voucherData),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        updatedVoucher = VoucherModel.fromJson(responseData);
        // Cập nhật item trong danh sách hiện tại thay vì fetch lại toàn bộ
        int index = _vouchers.indexWhere((v) => v.id == voucherId);
        if (index != -1) {
          _vouchers[index] = updatedVoucher;
        } else {
          await fetchVouchers(page: 0, size: _pageData?.size ?? 10, sort: 'id,desc');
        }
      } else {
        _errorMessage = responseData['message'] as String? ?? 'Lỗi cập nhật voucher.';
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi cập nhật voucher: ${e.toString()}";
    }
    _isLoading = false;
    notifyListeners();
    return updatedVoucher;
  }

  // Xóa/Vô hiệu hóa voucher
  Future<bool> deleteVoucher(int voucherId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;

    try {
      final url = Uri.parse('$_baseUrl/$voucherId');
      final response = await http.delete(url, headers: {'Content-Type': 'application/json; charset=UTF-8'}); // TODO: Thêm auth header

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      // API của bạn trả về 200 OK hoặc 409 Conflict với message
      if (response.statusCode == 200 || response.statusCode == 409) {
        success = true;
        // Tải lại danh sách để cập nhật trạng thái (nếu voucher được deactive thay vì xóa)
        await fetchVouchers(page: 0, size: _pageData?.size ?? 10, sort: 'id,desc');
        _errorMessage = responseData['message']; // Hiển thị thông báo từ backend
      } else {
        _errorMessage = responseData['message'] as String? ?? 'Lỗi xóa voucher.';
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi xóa voucher: ${e.toString()}";
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}