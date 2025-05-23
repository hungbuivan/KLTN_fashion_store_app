import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/chart_data.dart';

class StatsApiService {
  final String baseUrl = 'http://10.2.0.0:8080/api/admin'; // đổi theo backend

  Future<List<ChartData>> fetchRevenue() async {
    final response = await http.get(Uri.parse('$baseUrl/revenue'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => ChartData.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load revenue data');
    }
  }

  Future<List<ChartData>> fetchSoldProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products-sold'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => ChartData.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load product data');
    }
  }

  Future<List<ChartData>> fetchOrderStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/order-status'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => ChartData.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load order status');
    }
  }
}
