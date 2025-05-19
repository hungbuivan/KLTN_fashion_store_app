// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../../providers/stats_provider.dart';
//
// class AdminDashboard extends StatefulWidget {
//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }
//
// class _AdminDashboardState extends State<AdminDashboard> {
//   @override
//   void initState() {
//     super.initState();
//     Provider.of<StatsProvider>(context, listen: false).loadStats();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final stats = Provider.of<StatsProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Admin Dashboard")),
//       body: stats.isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text("📈 Doanh thu theo năm", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             _buildBarChart(stats.revenue),
//
//             SizedBox(height: 32),
//             Text("📊 Số lượng sản phẩm đã bán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             _buildBarChart(stats.soldProducts),
//
//             SizedBox(height: 32),
//             Text("🟠 Trạng thái đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             _buildPieChart(stats.orderStatus),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBarChart(List data) {
//     return SizedBox(
//       height: 250,
//       child: BarChart(
//         BarChartData(
//           barGroups: data.asMap().entries.map((entry) {
//             int index = entry.key;
//             var d = entry.value;
//             return BarChartGroupData(x: index, barRods: [
//               BarChartRodData(toY: d.value, color: Colors.blueAccent, width: 20)
//             ]);
//           }).toList(),
//           titlesData: FlTitlesData(
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 getTitlesWidget: (value, meta) {
//                   final index = value.toInt();
//                   if (index >= 0 && index < data.length) {
//                     return Text(data[index].label);
//                   }
//                   return Text('');
//                 },
//               ),
//             ),
//             leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPieChart(List data) {
//     return SizedBox(
//       height: 250,
//       child: PieChart(
//         PieChartData(
//           sections: data.map((d) {
//             return PieChartSectionData(
//               title: "${d.label}\n${d.value.toInt()}",
//               value: d.value,
//               color: _getColorByLabel(d.label),
//               radius: 60,
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Color _getColorByLabel(String label) {
//     switch (label.toLowerCase()) {
//       case 'completed':
//         return Colors.green;
//       case 'processing':
//         return Colors.orange;
//       case 'pending':
//         return Colors.blueGrey;
//       case 'cancelled':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//
// }


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
  @override
  void initState() {
    super.initState();
    final dashboardProvider = context.read<DashboardProvider>();
    dashboardProvider.fetchDashboardStats();
  }
// Khai báo formatter 1 lần
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    if (dashboard.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
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
