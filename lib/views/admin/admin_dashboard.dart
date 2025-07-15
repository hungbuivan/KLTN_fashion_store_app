import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fashion_store_app/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    final dashboardProvider = context.read<DashboardProvider>();
    dashboardProvider.fetchDashboardStats();
  }

  Future<void> _refreshDashboard() async {
    await context.read<DashboardProvider>().fetchDashboardStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã làm mới thống kê')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    if (dashboard.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Cho phép kéo khi không đủ độ cao
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard('Tổng đơn hàng', dashboard.totalOrders.toString(), Icons.shopping_cart),
            _buildStatCard('Tổng doanh thu', currencyFormatter.format(dashboard.totalRevenue), Icons.attach_money),
            _buildStatCard('Đang chuẩn bị', dashboard.pending.toString(), Icons.checklist),
            _buildStatCard('Đơn đã bán', dashboard.completed.toString(), Icons.check_circle),
            _buildStatCard('Đang giao', dashboard.processing.toString(), Icons.local_shipping),
            _buildStatCard('Đơn huỷ', dashboard.cancelled.toString(), Icons.cancel),
            _buildStatCard('Tổng sản phẩm', dashboard.totalProducts.toString(), Icons.store),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
