class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'],
      value: (json['value'] as num).toDouble(),
    );
  }
}
