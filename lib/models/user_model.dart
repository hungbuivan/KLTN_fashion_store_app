// file: lib/models/user_model.dart
// Cần cho UniqueKey nếu dùng làm fallback (hiện tại không cần)

// Class User đã được cập nhật theo yêu cầu của bạn
class User {
  final int id;           // ID người dùng, kiểu int
  final String fullName;   // Họ và tên đầy đủ, bắt buộc
  final String username;   // Tên đăng nhập (từ json['name']), bắt buộc
  final String email;      // Email, bắt buộc
  final String password;   // Mật khẩu, bắt buộc (LƯU Ý: Cẩn thận khi xử lý mật khẩu)
  final String address;    // Địa chỉ, bắt buộc
  final String role;       // Vai trò, bắt buộc
  final String phone;      // Số điện thoại, bắt buộc
  final String gender;     // Giới tính, bắt buộc
  final String avt_url;     // Giới tính, bắt buộc
  // Trường avatarUrl đã được loại bỏ theo cấu trúc mới bạn cung cấp

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.address,
    required this.role,
    required this.phone,
    required this.gender,
    required this.avt_url,
  });

  // Factory constructor để parse JSON từ response của backend
  // Đã cập nhật để khớp với cấu trúc User mới và mapping JSON bạn cung cấp
  factory User.fromJson(Map<String, dynamic> jsonMap) {
    return User(
      // Giả sử 'id' từ JSON luôn là int hoặc có thể parse thành int
      id: (jsonMap['id'] as num).toInt(), // Chuyển đổi sang int
      // Ánh xạ 'full_name' từ JSON sang thuộc tính fullName
      fullName: jsonMap['fullName'] as String? ?? '', // Cung cấp giá trị mặc định nếu null
      // Ánh xạ 'name' từ JSON sang thuộc tính username
      username: jsonMap['name'] as String? ?? '', // Cung cấp giá trị mặc định nếu null
      email: jsonMap['email'] as String? ?? '',
      password: jsonMap['password'] as String? ?? '', // Lấy mật khẩu
      address: jsonMap['address'] as String? ?? '',
      role: jsonMap['role'] as String? ?? 'user', // Mặc định role là 'user' nếu null
      phone: jsonMap['phone'] as String? ?? '',
      gender: jsonMap['gender'] as String? ?? '',
      avt_url: jsonMap['avatarUrl'] as String? ?? '',

    );
  }

  // Phương thức toJson() đã được cập nhật
  // Chuyển đổi đối tượng User thành một Map<String, dynamic>
  // để có thể được jsonEncode và lưu trữ.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName, // Sử dụng key 'full_name' để nhất quán nếu cần gửi lại cho server
      'name': username,    // Sử dụng key 'name' cho username
      'email': email,
      'password': password, // LƯU Ý: Cẩn thận khi bao gồm mật khẩu trong toJson,
      // đặc biệt nếu dùng để lưu trữ ở client mà không mã hóa thêm.
      'address': address,
      'role': role,
      'phone': phone,
      'gender': gender,
      'avt_url': avt_url,
      // không còn 'avatarUrl'
    };
  }
}
