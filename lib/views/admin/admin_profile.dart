// file: lib/views/admin/admin_profile.dart
import 'package:fashion_store_app/views/admin/product_management_page.dart';
import 'package:fashion_store_app/views/admin/revenue_page.dart';
import 'package:fashion_store_app/views/admin/user_management_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../providers/auth_provider.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/admin/pages/order_management_page.dart';
import '../../screens/admin/pages/voucher_management_page.dart';

class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) {
      if (url.contains('://localhost:8080')) return url.replaceFirst('://localhost:8080', serverBase);
      return url;
    }
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/avatars/$url';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final displayAvatarUrl = _fixImageUrl(user.avt_url);

        return Scaffold(
          // appBar: AppBar(
          //   title: const Text('Hồ sơ quản trị viên'),
          //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          //   elevation: 0,
          // ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: displayAvatarUrl.isNotEmpty
                            ? Image.network(
                          displayAvatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Iconsax.user, size: 40, color: Colors.grey.shade500),
                        )
                            : Icon(Iconsax.user, size: 40, color: Colors.grey.shade500),
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
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
                        Navigator.of(context).pushNamed(EditProfileScreen.routeName);
                      },
                      tooltip: 'Sửa thông tin',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                _buildAdminMenu(context),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
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

  Widget _buildAdminMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuTile(
          context: context,
          icon: Iconsax.box,
          title: 'Quản lý Sản phẩm',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductManagementPage())),
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.profile_2user,
          title: 'Quản lý Người dùng',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserManagementPage())),
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.receipt_item,
          title: 'Quản lý Đơn hàng',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminOrderManagementPage())),
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.ticket_discount,
          title: 'Quản lý Mã giảm giá',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminVoucherManagementPage())),
        ),
        _buildMenuTile(
          context: context,
          icon: Iconsax.graph,
          title: 'Quản lý Doanh thu',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RevenuePage())),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
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
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}