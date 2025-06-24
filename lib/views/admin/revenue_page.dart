import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenuePage extends StatefulWidget {
  const RevenuePage({super.key});

  @override
  State<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  String type = 'month';
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  DateTime? startDate;
  DateTime? endDate;
  double revenue = 0.0;
  bool loading = false;
  List<Map<String, dynamic>> chartData = [];

  final String baseUrl = 'http://10.0.2.2:8080/api/admin/stats';

  Future<void> fetchRevenue() async {
    setState(() {
      loading = true;
    });

    try {
      Uri uri;

      if (type == 'month') {
        uri = Uri.parse('$baseUrl/revenue/monthly?year=$selectedYear&month=$selectedMonth');
      } else if (type == 'year') {
        uri = Uri.parse('$baseUrl/revenue/yearly');
      } else {
        if (startDate == null || endDate == null) return;
        final formatter = DateFormat("yyyy-MM-dd");
        String start = formatter.format(startDate!);
        String end = formatter.format(endDate!);
        uri = Uri.parse('$baseUrl/revenue/custom?start=$start&end=$end');
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          if (type == 'year') {
            revenue = 0;
            chartData = [];
            for (var item in body) {
              final rev = double.tryParse(item['totalRevenue'].toString()) ?? 0.0;
              chartData.add({
                'label': item['year'].toString(),
                'value': rev,
              });
              revenue += rev;
            }
          } else if (type == 'month') {
            revenue = 0;
            chartData = [];
            for (var item in body) {
              final rev = double.tryParse(item['value'].toString()) ?? 0.0;
              chartData.add({
                'label': item['label'].toString(),
                'value': rev,
              });
              if (item['label'] == 'tháng $selectedMonth') {
                revenue = rev;
              }
            }
          } else {
            revenue = double.tryParse(body['totalRevenue'].toString()) ?? 0.0;
            chartData = [
              {
                'label': '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}',
                'value': revenue,
              }
            ];
          }
        });
      } else {
        throw Exception('Lỗi lấy dữ liệu');
      }
    } catch (e) {
      debugPrint("Lỗi fetchRevenue: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý doanh thu"),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: "Chọn kiểu thống kê",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'month', child: Text("Theo tháng")),
                    DropdownMenuItem(value: 'year', child: Text("Theo năm")),
                    DropdownMenuItem(value: 'range', child: Text("Theo khoảng ngày")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      type = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (type == 'month' || type == 'year') ...[
                  Row(
                    children: [
                      if (type == 'month')
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: const InputDecoration(
                              labelText: "Tháng",
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text("Tháng ${index + 1}"),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value!;
                              });
                            },
                          ),
                        ),
                      if (type == 'month') const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: const InputDecoration(
                            labelText: "Năm",
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(10, (index) {
                            final year = 2020 + index;
                            return DropdownMenuItem(
                              value: year,
                              child: Text("Năm $year"),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                if (type == 'range') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickDate(context, true),
                          child: Text(
                            startDate != null
                                ? "Từ: ${DateFormat('dd/MM/yyyy').format(startDate!)}"
                                : "Chọn ngày bắt đầu",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => pickDate(context, false),
                          child: Text(
                            endDate != null
                                ? "Đến: ${DateFormat('dd/MM/yyyy').format(endDate!)}"
                                : "Chọn ngày kết thúc",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blue,
                    ),
                    icon: const Icon(Icons.bar_chart, color: Colors.white),
                    label: const Text("Lấy doanh thu", style: TextStyle(fontSize: 16, color: Colors.white)),
                    onPressed: fetchRevenue,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: loading
                      ? const CircularProgressIndicator()
                      : Column(
                    children: [
                      const Text(
                        "Tổng doanh thu",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(revenue),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (chartData.isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= chartData.length) return const Text('');
                                      return Text(
                                        chartData[index]['label'],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                    reservedSize: 40,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    interval: 1000000,
                                    getTitlesWidget: (value, _) => Text(
                                      '${value ~/ 1000000}tr',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: chartData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (data['value'] as double),
                                      width: 20,
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
