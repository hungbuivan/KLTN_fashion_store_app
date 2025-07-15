// file: lib/providers/admin/product_admin_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// Đổi tên để tránh trùng với 'path' của Flutter
// << THÊM IMPORT NÀY

import 'package:fashion_store_app/models/admin/product_admin_model.dart';
import 'package:fashion_store_app/models/page_response_model.dart';

class ProductAdminProvider with ChangeNotifier {
  // ... (các biến và hàm fetchProducts, deleteProduct giữ nguyên) ...
  List<ProductAdminModel> _products = [];
  List<ProductAdminModel> get products => _products;

  PageResponse<ProductAdminModel>? _pageData;
  PageResponse<ProductAdminModel>? get pageData => _pageData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final String _baseUrl = 'http://10.0.2.2:8080/api/admin/products';

  Future<void> fetchProducts({
    int page = 0,
    int size = 10,
    String sort = 'id,asc',
    String? nameQuery,
    int? categoryId,
    int? brandId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };
      if (nameQuery != null && nameQuery.isNotEmpty) queryParams['name'] = nameQuery;
      if (categoryId != null) queryParams['categoryId'] = categoryId.toString();
      if (brandId != null) queryParams['brandId'] = brandId.toString();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      print("ProductAdminProvider: Fetching admin products from: $uri");
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _pageData = PageResponse.fromJson(responseData, ProductAdminModel.fromJson);
        if (_pageData != null) {
          _products = _pageData!.content;
        } else {
          _products = [];
        }

        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải sản phẩm: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}";
        _products = [];
        _pageData = null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý: ${e.toString()}";
      _products = [];
      _pageData = null;
      print("ProductAdminProvider: Error fetching admin products: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // ✅ SỬA LẠI HÀM NÀY
  Future<ProductAdminModel?> createProduct(
      Map<String, dynamic> productDataMap, {
        List<XFile>? imageFiles, // Nhận vào một danh sách file
      }) async {
    _errorMessage = null;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['productData'] = jsonEncode(productDataMap);

      // Thêm nhiều file vào request
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var file in imageFiles) {
          request.files.add(
              await http.MultipartFile.fromPath('imageFiles', file.path)
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return ProductAdminModel.fromJson(responseData);
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] ?? 'Lỗi tạo sản phẩm.';
        return null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối: ${e.toString()}";
      return null;
    }
  }


  // ✅ SỬA LẠI HÀM NÀY
  Future<ProductAdminModel?> updateProduct({
    required int productId,
    required Map<String, dynamic> productDataMap,
    List<XFile>? imageFiles, // Nhận vào một danh sách file mới
  }) async {
    _errorMessage = null;
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/$productId'));
      request.fields['productData'] = jsonEncode(productDataMap);

      // Thêm các file ảnh MỚI vào request
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (var file in imageFiles) {
          request.files.add(
              await http.MultipartFile.fromPath('imageFiles', file.path)
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return ProductAdminModel.fromJson(responseData);
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] ?? 'Lỗi cập nhật sản phẩm.';
        return null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối: ${e.toString()}";
      return null;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    bool success = false;
    try {
      final uri = Uri.parse('$_baseUrl/$productId');
      print("ProductAdminProvider: Deleting product: $uri");
      final response = await http.delete(uri);
      print("ProductAdminProvider: Delete product response status: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 204) {
        _errorMessage = null;
        success = true;
        int currentPage = _pageData?.number ?? 0;
        if ((_pageData?.content.length ?? 0) == 1 && currentPage > 0) {
          currentPage--;
        }
        await fetchProducts(page: currentPage, size: _pageData?.size ?? 10);
      } else {
        try {
          final responseData = jsonDecode(response.body);
          _errorMessage = "Lỗi xóa sản phẩm: ${responseData['message'] ?? responseData['error'] ?? response.body}";
        } catch (e) {
          _errorMessage = "Lỗi xóa sản phẩm: ${response.statusCode} - ${response.body}";
        }
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi xóa sản phẩm: ${e.toString()}";
      print("ProductAdminProvider: Error deleting product: $e");
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }
}