// file: lib/providers/admin/category_admin_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/admin/category_admin_model.dart';

class CategoryAdminProvider with ChangeNotifier {
  List<CategoryAdminModel> _categories = [];
  List<CategoryAdminModel> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Giả sử API trả về một danh sách các danh mục
  final String _apiUrl = 'http://10.0.2.2:8080/api/categories';

  Future<void> fetchAllCategories() async {
    if (_categories.isNotEmpty) return; // Chỉ tải nếu danh sách rỗng

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _categories = data.map((json) => CategoryAdminModel.fromJson(json)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Lỗi tải danh mục: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}
