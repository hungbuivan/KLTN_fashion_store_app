// file: lib/views/home/app_header.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart'; // ✅ Import AuthProvider (nơi chứa User model và trạng thái đăng nhập)
import '../../core/theme/constant.dart';   // ✅ Import file chứa biến imagePath

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ AuthProvider.
    // Khi AuthProvider gọi notifyListeners(), widget này sẽ được build lại.
    final authProvider = context.watch<AuthProvider>();
    final User? user = authProvider.user; // Lấy đối tượng User hiện tại (có thể null)

    // Xác định tên sẽ được hiển thị
    String displayName = "Guest"; // Giá trị mặc định nếu là khách hoặc không có tên

    if (user != null) { // Chỉ xử lý nếu người dùng đã đăng nhập (user object không null)
      // Ưu tiên 1: user.fullName
      if (user.fullName.isNotEmpty) { // Kiểm tra xem fullName có giá trị và không rỗng không
        displayName = user.fullName;
      }
      // Ưu tiên 2 (fallback): user.username (từ json['name'] theo model của bạn)
      // Chỉ dùng username nếu fullName rỗng hoặc không có
      else if (user.username.isNotEmpty) {
        displayName = user.username;
      }
      // Nếu cả fullName và username đều rỗng, có thể hiển thị một phần email hoặc "User"
      else if (user.email.isNotEmpty) {
        // displayName = user.email.split('@')[0]; // Lấy phần trước @ của email
        displayName = "User"; // Hoặc một tên chung chung
      }
      // Nếu tất cả đều rỗng (ít khả năng nếu email là bắt buộc), displayName sẽ vẫn là "User"
    }

    // Đường dẫn tới thư mục chứa ảnh (ví dụ: "assets/images/")
    // Đảm bảo biến imagePath được định nghĩa đúng trong constant.dart
    // Ví dụ: const String imagePath = "assets/images/";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ảnh đại diện
          CircleAvatar(
            radius: 30, // Kích thước avatar
            backgroundColor: Colors.grey.shade200, // Màu nền nếu ảnh có phần trong suốt
            // Luôn hiển thị ảnh user.png mặc định
            child: ClipOval( // Đảm bảo ảnh được cắt tròn
              child: Image.asset(
                "${imagePath}user.png", // Sử dụng đường dẫn từ constant.dart
                width: 60, // Kích thước bằng 2 lần radius
                height: 60,
                fit: BoxFit.cover, // Đảm bảo ảnh lấp đầy CircleAvatar
                errorBuilder: (context, error, stackTrace) {
                  // Xử lý nếu ảnh user.png không tải được
                  print("Lỗi load ảnh user.png trong AppHeader: $error");
                  return const Icon(Iconsax.user_octagon, size: 30, color: Colors.grey); // Icon lỗi
                },
              ),
            ),
          ),
          const SizedBox(width: 12), // Khoảng cách giữa ảnh và chữ

          // Cột chứa văn bản chào
          Expanded( // Cho phép Text co giãn và xuống dòng nếu cần
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Canh chữ sang trái
              mainAxisSize: MainAxisSize.min, // Cột chỉ chiếm chiều cao cần thiết
              children: [
                // Hiển thị "Hello, [Tên User]"
                Text(
                  "Hello, $displayName!", // Sử dụng displayName đã được xác định
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1, // Chỉ hiển thị 1 dòng
                  overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu tên quá dài
                ),
                const SizedBox(height: 2), // Khoảng cách nhỏ
                const Text(
                  "Good day for shopping!", // Dòng chào phụ
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Không cần Spacer ở đây nếu Column trên đã là Expanded

          // Các Icons ở cuối bên phải
          IconButton(
            icon: const Icon(Iconsax.notification, size: 28),
            onPressed: () {
              // TODO: Xử lý sự kiện nhấn nút thông báo
              print("Nút Notification được nhấn");
            },
            tooltip: "Notifications",
            color: Colors.grey[700],
          ),
          IconButton(
            icon: const Icon(Iconsax.shopping_cart, size: 28),
            onPressed: () {
              // TODO: Xử lý sự kiện nhấn nút giỏ hàng
              print("Nút Shopping Cart được nhấn");
            },
            tooltip: "Shopping Cart",
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
