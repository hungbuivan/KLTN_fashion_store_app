import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class RevenuePage extends StatefulWidget {
  const RevenuePage({super.key});

  @override
  State<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends State<RevenuePage> {
  String type = 'month'; // 'month', 'year', 'range'
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  DateTime? startDate;
  DateTime? endDate;
  double revenue = 0.0;
  bool loading = false;

  final String baseUrl = 'http://10.0.2.2:8080/api/admin/stats'; // Đổi thành địa chỉ backend của cậu

  Future<void> fetchRevenue() async {
    setState(() {
      loading = true;
    });

    try {
      Uri uri;

      if (type == 'month') {
        uri = Uri.parse('$baseUrl/revenue/monthly?year=$selectedYear&month=$selectedMonth');

      }

      else if (type == 'year') {
        uri = Uri.parse(
            '$baseUrl/revenue/yearly');
      } else {
        // range
        if (startDate == null || endDate == null) return;
        final formatter = DateFormat("yyyy-MM-dd");
        String start = formatter.format(startDate!);
        String end = formatter.format(endDate!);

        uri = Uri.parse(
            '$baseUrl/revenue/custom?start=$start&end=$end');
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        setState(() {
          if (type == 'year') {
            revenue = 0;
            for (var item in body) {
              revenue += double.tryParse(item['totalRevenue'].toString()) ?? 0.0;
            }
          } else if (type == 'month') {
            // CHỈ lấy doanh thu của tháng đã chọn
            revenue = 0;
            for (var item in body) {
              print("Label: ${item['label']}, Value: ${item['value']}");

              if (item['label'] == 'tháng $selectedMonth') {
                revenue = double.tryParse(item['value'].toString()) ?? 0.0;
                break;
              }
            }

          } else {
            revenue = double.tryParse(body['totalRevenue'].toString()) ?? 0.0;
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
        title: const Text("Thống kê doanh thu"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: type,
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
            const SizedBox(height: 12),
            if (type == 'month' || type == 'year') ...[
              Row(
                children: [
                  if (type == 'month')
                    DropdownButton<int>(
                      value: selectedMonth,
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
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: selectedYear,
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
                ],
              ),
            ],
            if (type == 'range') ...[
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => pickDate(context, true),
                    child: Text(
                      startDate != null
                          ? "Từ: ${DateFormat('dd/MM/yyyy').format(startDate!)}"
                          : "Chọn ngày bắt đầu",
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => pickDate(context, false),
                    child: Text(
                      endDate != null
                          ? "Đến: ${DateFormat('dd/MM/yyyy').format(endDate!)}"
                          : "Chọn ngày kết thúc",
                    ),
                  ),
                ],
              )
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchRevenue,
              child: const Text("Lấy doanh thu"),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : Text(
              "Tổng doanh thu: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(revenue)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
