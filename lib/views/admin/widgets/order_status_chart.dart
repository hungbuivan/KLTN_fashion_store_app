// lib/views/admin/widgets/order_status_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OrderStatusChart extends StatelessWidget {
  final Map<String, double> statusData;

  const OrderStatusChart({super.key, required this.statusData});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.green, Colors.orange, Colors.red];

    // Chuyển statusData.entries thành List để dùng asMap()
    final entries = statusData.entries.toList();

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Tình trạng đơn hàng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: entries
                      .asMap()
                      .entries
                      .map(
                        (e) => PieChartSectionData(
                      color: colors[e.key % colors.length],
                      value: e.value.value,
                      title: '${e.value.value.toInt()}',
                      radius: 60,
                    ),
                  )
                      .toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: entries.map((e) {
                final color =
                colors[entries.indexOf(e) % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(backgroundColor: color, radius: 5),
                    const SizedBox(width: 4),
                    Text(e.key),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }
}
