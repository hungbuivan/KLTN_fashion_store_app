// file: lib/models/admin/category_admin_model.dart

class CategoryAdminModel {
  final int id;
  final String name;
  // Bạn có thể thêm các trường khác nếu API trả về, ví dụ: parentId

  CategoryAdminModel({
    required this.id,
    required this.name,
  });

  factory CategoryAdminModel.fromJson(Map<String, dynamic> json) {
    return CategoryAdminModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'N/A',
    );
  }
}
