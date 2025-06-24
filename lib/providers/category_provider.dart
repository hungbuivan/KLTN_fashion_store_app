// file: lib/providers/category_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category_node_model.dart'; // Import model bạn vừa tạo

class CategoryProvider with ChangeNotifier {
  // URL của API backend để lấy cây danh mục
  final String _apiUrl = 'http://10.0.2.2:8080/api/categories/tree';

  // Danh sách để lưu trữ các nút gốc của cây danh mục
  List<CategoryNodeModel> _categoryTree = [];
  List<CategoryNodeModel> get categoryTree => _categoryTree;

  // Các biến quản lý trạng thái
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Constructor có thể tự động gọi fetch khi được tạo
  CategoryProvider() {
    fetchCategoryTree();
  }

  // Hàm gọi API để lấy dữ liệu cây danh mục từ backend
  Future<void> fetchCategoryTree() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Thông báo cho UI biết rằng quá trình tải bắt đầu

    try {
      print("CategoryProvider: Fetching category tree from $_apiUrl");
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes));

        // Sử dụng CategoryNodeModel.fromJson để parse dữ liệu
        _categoryTree = decodedData
            .map((json) => CategoryNodeModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print("CategoryProvider: Fetched ${_categoryTree.length} root categories successfully.");
      } else {
        _errorMessage = "Lỗi tải danh mục: ${response.statusCode}";
        print("CategoryProvider: Error fetching category tree - ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý dữ liệu: ${e.toString()}";
      print("CategoryProvider: Exception fetching category tree: $e");
    }

    _isLoading = false;
    notifyListeners(); // Thông báo cho UI biết rằng quá trình tải đã hoàn tất (thành công hoặc thất bại)
  }
}