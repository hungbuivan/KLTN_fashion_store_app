// file: lib/providers/product_detail_provider.dart
import 'dart:convert'; // Để sử dụng jsonEncode và jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Package để thực hiện HTTP requests
import '../models/product_detail_model.dart'; // ✅ Import ProductDetailModel đã được đơn giản hóa

// Import AuthProvider nếu API chi tiết sản phẩm yêu cầu token trong tương lai
// import 'auth_provider.dart';

class ProductDetailProvider with ChangeNotifier {
  ProductDetailModel? _product; // Sử dụng ProductDetailModel đã đơn giản hóa
  ProductDetailModel? get product => _product;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // URL cơ sở cho API products (thay đổi IP nếu cần cho emulator/thiết bị thật)
  final String _baseApiUrl = 'http://10.0.2.2:8080/api/products';

  // AuthProvider? _authProvider; // Dùng để lấy token nếu API yêu cầu
  // ProductDetailProvider(this._authProvider); // Constructor nếu cần AuthProvider

  // Hàm để lấy token (nếu API yêu cầu xác thực)
  // Future<Map<String, String>> _getHeaders() async {
  //   final headers = {'Content-Type': 'application/json; charset=UTF-8'};
  //   // final token = _authProvider?.token; // Giả sử AuthProvider có token
  //   // if (token != null) {
  //   //   headers['Authorization'] = 'Bearer $token';
  //   // }
  //   return headers;
  // }

  // Hàm gọi API để lấy chi tiết sản phẩm
  Future<void> fetchProductDetails(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    _product = null; // Xóa sản phẩm cũ trước khi tải mới để UI hiển thị loading đúng
    notifyListeners();

    try {
      // ✅ URL API giờ là /api/products/{productId} (không có /details)
      final url = Uri.parse('$_baseApiUrl/$productId');
      print("ProductDetailProvider: Đang tải chi tiết sản phẩm từ: $url");

      // final headers = await _getHeaders(); // Dùng khi có xác thực
      // final response = await http.get(url, headers: headers);
      final response = await http.get(url); // Hiện tại chưa có auth

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes); // Xử lý tiếng Việt
        print("ProductDetailProvider: Phản hồi API chi tiết sản phẩm: $responseBody");
        final Map<String, dynamic> decodedData = jsonDecode(responseBody);
        // ✅ Sử dụng ProductDetailModel.fromJson đã được đơn giản hóa
        _product = ProductDetailModel.fromJson(decodedData);
        _errorMessage = null;
      } else if (response.statusCode == 404) {
        _errorMessage = "Không tìm thấy sản phẩm với ID: $productId.";
        _product = null;
      }
      else {
        _errorMessage = "Lỗi tải chi tiết sản phẩm: ${response.statusCode} - ${response.body}";
        _product = null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý khi lấy chi tiết sản phẩm: ${e.toString()}";
      _product = null;
      print("ProductDetailProvider: Lỗi fetchProductDetails: $e");
    }

    _isLoading = false;
    notifyListeners(); // Thông báo cho UI cập nhật
  }

  // Hàm để reset trạng thái khi rời màn hình hoặc tải sản phẩm mới
  void clearProductDetails() {
    _product = null;
    _isLoading = false; // Có thể đặt lại isLoading nếu muốn
    _errorMessage = null;
    // Không gọi notifyListeners() ở đây nếu không muốn UI build lại ngay lập tức
    // mà sẽ đợi fetchProductDetails gọi khi cần.
    // Nếu muốn UI reset ngay, hãy gọi notifyListeners().
    // notifyListeners();
  }
}
