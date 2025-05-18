// file: lib/models/common/page_response_model.dart
class PageResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int number; // Trang hiện tại (0-indexed)
  final int size;   // Kích thước trang
  final bool first;
  final bool last;
  final bool empty;

  PageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PageResponse(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      first: json['first'] as bool? ?? false,
      last: json['last'] as bool? ?? false,
      empty: json['empty'] as bool? ?? true,
    );
  }
}