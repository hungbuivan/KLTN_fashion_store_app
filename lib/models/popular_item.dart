// popular_item.dart (ví dụ)
class PopularItem {
  final int id; // Hoặc int tùy backend
  final String name; // Thêm các trường khác nếu cần
  final double price;
  final String imageUrl;
  final bool? isFavorite; // Có thể null nếu backend không trả về
  final bool? isPopular; // Có thể null nếu backend không trả về

  PopularItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isFavorite,
    this.isPopular,
  });

  // Factory constructor để parse JSON
  factory PopularItem.fromJson(Map<String, dynamic> json) {
    return PopularItem(
      id: json['id'], // Đảm bảo kiểu dữ liệu khớp
      name: json['name'] ?? '', // Cung cấp giá trị mặc định nếu cần
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'] as String,
      isFavorite: json['isFavorite'] as bool?,
      isPopular: json['isPopular'] as bool?,
    );
  }
}