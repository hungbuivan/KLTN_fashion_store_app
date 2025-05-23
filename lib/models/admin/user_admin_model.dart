// file: lib/models/admin/user_admin_model.dart

class UserAdminModel {
  final int id; // Backend của bạn trả về ID là Long, nhưng ở Flutter int có thể xử lý số lớn
  final String? fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String role;
  final String? gender;
  final bool isActive; // Trạng thái hoạt động của tài khoản
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserAdminModel({
    required this.id,
    this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.avatarUrl,
    required this.role,
    this.gender,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String?,
      email: json['email'] as String? ?? 'N/A', // Xử lý null cho email
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'user', // Mặc định là 'user' nếu null
      gender: json['gender'] as String?,
      isActive: json['active'] as bool? ?? false, // Lấy trạng thái active, mặc định là false nếu null
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

// toJson không cần thiết nếu provider này chỉ đọc và cập nhật từng phần
// Nhưng nếu có form sửa toàn bộ thông tin user thì sẽ cần
}