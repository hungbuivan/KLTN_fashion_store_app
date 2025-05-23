// lib/views/admin/widgets/revenue_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RevenueChart extends StatelessWidget {
  final List<double> revenueData;

  const RevenueChart({super.key, required this.revenueData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Doanh thu theo tháng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  barGroups: revenueData
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(toY: e.value, color: Colors.blue, width: 16, borderRadius: BorderRadius.circular(4))
                    ],
                  ))
                      .toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text('T${value.toInt() + 1}'),
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
