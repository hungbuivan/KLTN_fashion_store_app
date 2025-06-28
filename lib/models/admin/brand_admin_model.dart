// file: lib/models/admin/brand_admin_model.dart

class BrandAdminModel {
  final int id;
  final String name;
  // Bạn có thể thêm các trường khác nếu API trả về, ví dụ: imageUrl

  BrandAdminModel({
    required this.id,
    required this.name,
  });

  factory BrandAdminModel.fromJson(Map<String, dynamic> json) {
    return BrandAdminModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'N/A',
    );
  }
}
