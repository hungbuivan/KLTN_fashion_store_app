import 'package:flutter/material.dart';
import '../core/services/stats_api_service.dart';
import '../models/chart_data.dart';

class StatsProvider with ChangeNotifier {
  final api = StatsApiService();

  List<ChartData> revenue = [];
  List<ChartData> soldProducts = [];
  List<ChartData> orderStatus = [];

  bool isLoading = true;

  Future<void> loadStats() async {
    isLoading = true;
    notifyListeners();

    try {
      revenue = await api.fetchRevenue();
      soldProducts = await api.fetchSoldProducts();
      orderStatus = await api.fetchOrderStatus();
    } catch (e) {
      print('Error loading stats: $e');
    }

    isLoading = false;
    notifyListeners();
  }
}
