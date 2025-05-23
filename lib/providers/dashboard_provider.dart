import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardProvider extends ChangeNotifier {
  int totalOrders = 0;
  double totalRevenue = .0;
  int pending = 0;
  int completed = 0;
  int processing = 0;
  int cancelled = 0;
  int totalProducts = 0;
  bool isLoading = true;

  Future<void> fetchDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/api/admin/dashboard/stats')); // Thay IP nếu cần

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('Dashboard API response: $data');
        totalOrders = data['totalOrders'] ?? 0;
        totalRevenue = (data['totalRevenue'] ?? 0).toDouble();

        pending = data['pendingOrders'] ?? 0;
        completed = data['completedOrders'] ?? 0;
        processing = data['processingOrders'] ?? 0;
        cancelled = data['cancelledOrders'] ?? 0;
        totalProducts = data['totalProducts'] ?? 0;

      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      print("Lỗi khi gọi API dashboard: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
