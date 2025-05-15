import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/product_model.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080/api/products";

  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> data = decoded is List ? decoded : decoded['data'] ?? [];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

  // 🆕 Thêm hàm này để gọi /popular
  static Future<List<Product>> fetchPopularProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/popular'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> data = decoded is List ? decoded : decoded['data'] ?? [];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load popular products");
    }
  }
}
