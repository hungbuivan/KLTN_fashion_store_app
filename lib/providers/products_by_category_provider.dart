// file: lib/providers/products_by_category_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import các model cần thiết
import '../models/page_response_model.dart';
import '../models/product_summary_model.dart';
//import '../models/common/page_response_model.dart'; // Giả sử bạn đã có model này

class ProductsByCategoryProvider with ChangeNotifier {
  final String _baseUrl = 'http://10.0.2.2:8080/api/products';

  // State
  List<ProductSummaryModel> _products = [];
  List<ProductSummaryModel> get products => _products;

  PageResponse<ProductSummaryModel>? _pageData;
  PageResponse<ProductSummaryModel>? get pageData => _pageData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ✅ HÀM ĐÃ ĐƯỢC CẬP NHẬT ĐỂ XỬ LÝ PAGE OBJECT
  Future<void> fetchProductsByCategoryId(
      int categoryId, {
        int page = 0,
        int size = 20,
        String sort = 'createdAt,desc',
      }) async {
    _isLoading = true;
    _errorMessage = null;
    // Chỉ thông báo loading toàn màn hình khi tải trang đầu tiên
    if (page == 0) {
      notifyListeners();
    }

    try {
      final queryParams = {
        'categoryId': categoryId.toString(),
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print("ProductsByCategoryProvider: Fetching products from: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Parse response thành Map thay vì List
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        // Sử dụng PageResponse model để parse dữ liệu phân trang
        _pageData = PageResponse.fromJson(responseData, (json) => ProductSummaryModel.fromJson(json));

        if (page == 0) {
          _products = _pageData!.content; // Thay thế danh sách cũ
        } else {
          _products.addAll(_pageData!.content); // Thêm vào danh sách hiện tại khi tải thêm trang
        }
        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải sản phẩm: ${response.statusCode}";
        if (page == 0) _products = [];
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý: ${e.toString()}";
      if (page == 0) _products = [];
      print("ProductsByCategoryProvider: Error fetching products: $e");
    }

    _isLoading = false;
    notifyListeners();
  }


  // Hàm để dọn dẹp dữ liệu khi rời khỏi màn hình
  void clearProducts() {
    _products = [];
    _pageData = null;
    _errorMessage = null;
    _isLoading = false;
    // Không cần gọi notifyListeners() ở đây để tránh việc màn hình cũ bị build lại không cần thiết
  }
}