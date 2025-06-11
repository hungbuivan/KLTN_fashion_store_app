// file: lib/screens/account_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Import các provider và màn hình cần thiết
import '../providers/auth_provider.dart';
import 'order_history_screen.dart'; // Để điều hướng đến lịch sử đơn hàng
import 'edit_profile_screen.dart';  // Màn hình sửa thông tin (sẽ tạo ở bước sau)

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Hàm helper để fix URL ảnh (tương tự các màn hình khác)
  String _fixImageUrl(String? originalUrlFromApi) {
    const String serverBase = "http://10.0.2.2:8080";
    if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
      return ''; // Không có ảnh
    }
    if (originalUrlFromApi.startsWith('http')) {
      if (originalUrlFromApi.contains('://localhost:8080')) {
        return originalUrlFromApi.replaceFirst('://localhost:8080', serverBase);
      }
      return originalUrlFromApi;
    }
    if (originalUrlFromApi.startsWith('/')) {
      return serverBase + originalUrlFromApi;
    }
    return '$serverBase/images/avatars/$originalUrlFromApi'; // Giả sử path cho avatar
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer để lấy AuthProvider và tự động cập nhật khi có thay đổi
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Nếu người dùng là khách (chưa đăng nhập), hiển thị giao diện đăng nhập
        if (authProvider.isGuest || authProvider.user == null) {
          return _buildGuestView(context);
        }

        // Nếu đã đăng nhập, hiển thị thông tin tài khoản
        final user = authProvider.user!;
        final displayAvatarUrl = _fixImageUrl(user.avt_url);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tài khoản của tôi'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              children: [
                // Phần thông tin cá nhân
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (displayAvatarUrl.isNotEmpty)
                          ? NetworkImage(displayAvatarUrl)
                          : null,
                      child: (displayAvatarUrl.isEmpty)
                          ? Icon(
                        Iconsax.user,
                        size: 40,
                        color: Colors.grey.shade500,
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? 'Chưa có tên',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Iconsax.edit, color: Theme.of(context).colorScheme.primary),
                      onPressed: () {
                        // Điều hướng đến trang sửa thông tin
                        Navigator.of(context).pushNamed(EditProfileScreen.routeName);
                      },
                      tooltip: 'Sửa thông tin',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Danh sách các tùy chọn
                _buildProfileMenu(context),

                const SizedBox(height: 30),

                // Nút Đăng xuất
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      // Gọi hàm logout từ AuthProvider
                      await context.read<AuthProvider>().logout();
                      // Sau khi logout, AuthProvider sẽ thông báo thay đổi và widget này sẽ tự rebuild
                      // để hiển thị _buildGuestView.
                      // Không cần điều hướng ở đây nếu AccountPage là một tab của BottomNavigationBar
                      // vì Consumer sẽ tự xử lý việc thay đổi UI.
                      // Nếu bạn muốn pop về màn hình login, có thể thêm:
                      // Navigator.of(context).pushNamedAndRemoveUntil('/login_input', (route) => false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget cho giao diện khi người dùng chưa đăng nhập
  Widget _buildGuestView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.profile_circle, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'Vui lòng đăng nhập',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                'Đăng nhập để quản lý tài khoản, xem lịch sử đơn hàng và nhận nhiều ưu đãi hơn!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Điều hướng đến trang đăng nhập
                  Navigator.of(context).pushNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                ),
                child: const Text('Đăng nhập / Đăng ký', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget cho phần menu các tùy chọn
  Widget _buildProfileMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuTile(
          context: context,
          icon: Iconsax.user_edit,
          title: 'Thông tin cá nhân',
          subtitle: 'Thay đổi thông tin, mật khẩu',
          onTap: () {
            Navigator.of(context).pushNamed(EditProfileScreen.routeName);
          },
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.box_tick,
          title: 'Lịch sử Đơn hàng',
          subtitle: 'Xem các đơn hàng đã đặt',
          onTap: () {
            Navigator.of(context).pushNamed(OrderHistoryScreen.routeName);
          },
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.location,
          title: 'Sổ địa chỉ',
          subtitle: 'Quản lý địa chỉ giao hàng',
          onTap: () {
            // TODO: Tạo và điều hướng đến ManageAddressesScreen
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển!')));
          },
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.ticket_discount,
          title: 'Kho Voucher',
          subtitle: 'Xem các mã giảm giá của bạn',
          onTap: () {
            // TODO: Tạo và điều hướng đến UserVouchersScreen
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng đang phát triển!')));
          },
        ),
      ],
    );
  }

  // Widget helper cho mỗi dòng trong menu
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}