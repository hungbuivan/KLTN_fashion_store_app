// lib/views/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const Text('Biểu đồ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 30, color: Colors.blue)]), // Tồn kho
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 50, color: Colors.green)]), // Đã bán
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 20, color: Colors.orange)]), // Hết hàng
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Tồn kho');
                            case 1:
                              return const Text('Đã bán');
                            case 2:
                              return const Text('Hết hàng');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
