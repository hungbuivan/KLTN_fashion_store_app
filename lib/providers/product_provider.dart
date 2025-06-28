// file: lib/providers/product_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/page_response_model.dart';
import '../models/product_summary_model.dart';

class ProductProvider with ChangeNotifier {
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

  // ✅ THÊM STATE MỚI CHO SẢN PHẨM PHỔ BIẾN
  List<ProductSummaryModel> _popularProducts = [];
  List<ProductSummaryModel> get popularProducts => _popularProducts;
  bool _isLoadingPopular = false;
  bool get isLoadingPopular => _isLoadingPopular;
  String? _errorPopularMessage;
  String? get errorPopularMessage => _errorPopularMessage;
  // ✅ THÊM HÀM MỚI
  Future<void> fetchPopularProducts() async {
    _isLoadingPopular = true;
    _errorPopularMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/popular');
      print("ProductProvider: Fetching popular products from: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));

        // Sử dụng model mới để parse dữ liệu
        _popularProducts = responseData
            .map((json) => ProductSummaryModel.fromJson(json as Map<String, dynamic>))
            .toList();

      } else {
        _errorPopularMessage = "Lỗi tải sản phẩm phổ biến: ${response.statusCode}";
      }
    } catch (e) {
      _errorPopularMessage = "Lỗi kết nối: ${e.toString()}";
      print("ProductProvider: Error fetching popular products: $e");
    }

    _isLoadingPopular = false;
    notifyListeners();
  }



  // Hàm fetchProducts linh hoạt, có thể nhận các tham số lọc
  Future<void> fetchProducts({
    int page = 0,
    int size = 10,
    String sort = 'createdAt,desc',
    String? searchTerm,
    int? categoryId,
  }) async {
    // Chỉ hiển thị loading toàn trang khi tải lần đầu
    if (page == 0) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['searchTerm'] = searchTerm;
      }
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId.toString();
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print("ProductProvider: Fetching products from: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Parse response thành Map vì backend trả về Page object
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        // Sử dụng PageResponse model để parse dữ liệu phân trang
        _pageData = PageResponse.fromJson(responseData, (json) => ProductSummaryModel.fromJson(json));

        if (page == 0) {
          _products = _pageData!.content; // Tải mới, thay thế danh sách cũ
        } else {
          _products.addAll(_pageData!.content); // Tải thêm trang, thêm vào danh sách
        }
      } else {
        _errorMessage = "Lỗi tải sản phẩm: ${response.statusCode}";
        if (page == 0) _products = [];
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối: ${e.toString()}";
      if (page == 0) _products = [];
      print("ProductProvider: Error fetching products: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hàm dọn dẹp state
  void clear() {
    _products = [];
    _pageData = null;
    _errorMessage = null;
    _isLoading = false;
  }
}
