// file: lib/providers/admin/brand_admin_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/admin/brand_admin_model.dart';

class BrandAdminProvider with ChangeNotifier {
  List<BrandAdminModel> _brands = [];
  List<BrandAdminModel> get brands => _brands;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Giả sử API trả về một danh sách các thương hiệu
  final String _apiUrl = 'http://10.0.2.2:8080/api/brands';

  Future<void> fetchAllBrands() async {
    if (_brands.isNotEmpty) return; // Chỉ tải nếu danh sách rỗng

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _brands = data.map((json) => BrandAdminModel.fromJson(json)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Lỗi tải thương hiệu: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }
}
