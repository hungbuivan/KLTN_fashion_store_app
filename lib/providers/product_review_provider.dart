// file: lib/providers/product_review_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/page_response_model.dart';
import '../models/review_model.dart';
import 'auth_provider.dart';

class ProductReviewProvider with ChangeNotifier {
  final AuthProvider authProvider;
  final String _baseUrl = 'http://10.0.2.2:8080/api/products';

  ProductReviewProvider(this.authProvider);

  // State
  List<ReviewModel> _reviews = [];
  List<ReviewModel> get reviews => _reviews;

  PageResponse<ReviewModel>? _pageData;
  PageResponse<ReviewModel>? get pageData => _pageData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Hàm lấy danh sách đánh giá cho một sản phẩm
  Future<void> fetchReviews(int productId, {int page = 0, int size = 5}) async {
    _isLoading = true;
    if (page == 0) {
      _reviews = []; // Xóa dữ liệu cũ khi tải lại từ đầu
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/$productId/reviews?page=$page&size=$size&sort=createdAt,desc');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _pageData = PageResponse.fromJson(responseData, (json) => ReviewModel.fromJson(json));

        if (page == 0) {
          _reviews = _pageData!.content;
        } else {
          _reviews.addAll(_pageData!.content);
        }
      } else {
        _errorMessage = 'Lỗi tải đánh giá: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hàm gửi một đánh giá mới
  Future<bool> submitReview({
    required int productId,
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để đánh giá.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      final url = Uri.parse('$_baseUrl/$productId/reviews');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'userId': authProvider.user!.id,
          'orderId': orderId,
          'productId': productId,
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201) {
        // Tạo đánh giá thành công, tải lại danh sách review cho sản phẩm đó
        await fetchReviews(productId);
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] ?? 'Gửi đánh giá thất bại.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
