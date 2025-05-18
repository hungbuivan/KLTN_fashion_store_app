// file: lib/providers/admin/product_admin_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_helper; // Đổi tên để tránh trùng với 'path' của Flutter
import 'package:http_parser/http_parser.dart'; // << THÊM IMPORT NÀY

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
        _products = _pageData!.content;
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


  Future<ProductAdminModel?> createProduct(
      Map<String, dynamic> productDataMap, { // Đổi tên productData thành productDataMap để rõ ràng hơn
        File? imageFile,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ProductAdminModel? createdProduct;
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

      // ***** SỬA ĐỔI QUAN TRỌNG Ở ĐÂY *****
      // Gửi productDataMap dưới dạng một part JSON có tên "productData"
      request.files.add(http.MultipartFile.fromString(
        'productData', // Phải khớp với @RequestPart("productData") ở backend
        jsonEncode(productDataMap),
        contentType: MediaType('application', 'json'), // Quan trọng!
      ));
      // *************************************

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'imageFile', // Phải khớp với @RequestPart("imageFile") ở backend
            imageFile.path,
            filename: path_helper.basename(imageFile.path),
          ),
        );
        print("ProductAdminProvider: Uploading image file: ${imageFile.path}");
      } else {
        print("ProductAdminProvider: No image file to upload for create.");
      }

      print("ProductAdminProvider: Creating product with files: ${request.files.map((f) => 'Field: ${f.field}, Filename: ${f.filename}, ContentType: ${f.contentType}').toList()}");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("ProductAdminProvider: Create product response status: ${response.statusCode}");
      print("ProductAdminProvider: Create product response body: ${response.body}"); // Dùng response.body

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        createdProduct = ProductAdminModel.fromJson(responseData);
        _errorMessage = null;
        await fetchProducts(page: 0, size: _pageData?.size ?? 10, sort: 'id,desc');
      } else {
        try {
          final responseData = jsonDecode(response.body);
          _errorMessage = "Lỗi tạo sản phẩm: ${responseData['message'] ?? responseData['error'] ?? response.body}";
        } catch (e) {
          _errorMessage = "Lỗi tạo sản phẩm (không parse được JSON): ${response.statusCode} - ${response.body}";
        }
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý khi tạo sản phẩm: ${e.toString()}";
      print("ProductAdminProvider: Error creating product: $e");
    }

    _isLoading = false;
    notifyListeners();
    return createdProduct;
  }

  Future<ProductAdminModel?> updateProduct(
      int productId,
      Map<String, dynamic> productDataMap, { // Đổi tên productData thành productDataMap
        File? imageFile,
        // bool removeCurrentImage = false, // Cờ này nên được gửi bên trong productDataMap
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ProductAdminModel? updatedProduct;
    try {
      final uri = Uri.parse('$_baseUrl/$productId');
      var request = http.MultipartRequest('PUT', uri);

      // ***** SỬA ĐỔI QUAN TRỌNG Ở ĐÂY *****
      // Gửi productDataMap dưới dạng một part JSON có tên "productData"
      // productDataMap nên chứa cả cờ removeCurrentImage nếu cần
      // ví dụ: productDataMap['removeCurrentImage'] = true; (được set từ AddEditProductScreen)
      request.files.add(http.MultipartFile.fromString(
        'productData', // Phải khớp với @RequestPart("productData") ở backend
        jsonEncode(productDataMap),
        contentType: MediaType('application', 'json'), // Quan trọng!
      ));
      // *************************************

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'imageFile', // Phải khớp với @RequestPart("imageFile") ở backend
            imageFile.path,
            filename: path_helper.basename(imageFile.path),
          ),
        );
        print("ProductAdminProvider: Uploading new image file for update: ${imageFile.path}");
      } else {
        print("ProductAdminProvider: No new image file to upload for update.");
      }

      print("ProductAdminProvider: Updating product $productId with files: ${request.files.map((f) => 'Field: ${f.field}, Filename: ${f.filename}, ContentType: ${f.contentType}').toList()}");


      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("ProductAdminProvider: Update product response status: ${response.statusCode}");
      print("ProductAdminProvider: Update product response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        updatedProduct = ProductAdminModel.fromJson(responseData);
        _errorMessage = null;
        // Cân nhắc chỉ cập nhật item trong danh sách thay vì fetch lại toàn bộ
        await fetchProducts(
          page: _pageData?.number ?? 0,
          size: _pageData?.size ?? 10,
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          _errorMessage = "Lỗi cập nhật sản phẩm: ${responseData['message'] ?? responseData['error'] ?? response.body}";
        } catch (e) {
          _errorMessage = "Lỗi cập nhật sản phẩm (không parse được JSON): ${response.statusCode} - ${response.body}";
        }
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý khi cập nhật sản phẩm: ${e.toString()}";
      print("ProductAdminProvider: Error updating product: $e");
    }

    _isLoading = false;
    notifyListeners();
    return updatedProduct;
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