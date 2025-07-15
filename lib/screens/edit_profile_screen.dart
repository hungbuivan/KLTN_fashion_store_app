import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../providers/edit_profile_provider.dart';
import '../providers/auth_provider.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  static const routeName = '/edit-profile';

  // Hàm fix URL giống y như AllReviewsScreen
  String _fixAvatarUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/avatars/$url';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<AuthProvider, EditProfileProvider>(
      create: (context) => EditProfileProvider(
        Provider.of<AuthProvider>(context, listen: false),
      ),
      update: (context, auth, previous) {
        if (previous == null) return EditProfileProvider(auth);

        previous.authProvider = auth;

        if (previous.authProvider.user?.id != auth.user?.id) {
          previous.initialize();
        }
        return previous;
      },
      child: const EditProfileView(),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  String _fixAvatarUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/avatars/$url';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EditProfileProvider>(context, listen: false).initialize();
    });
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formKey.currentState!.save();

    final provider = context.read<EditProfileProvider>();

    // 1. Gọi cập nhật thông tin cá nhân
    final profileSuccess = await provider.updateUserProfile();

    // 2. Nếu có nhập mật khẩu thì đổi mật khẩu
    bool passwordSuccess = true;
    if (provider.currentPasswordController.text.isNotEmpty ||
        provider.newPasswordController.text.isNotEmpty ||
        provider.confirmPasswordController.text.isNotEmpty) {
      passwordSuccess = await provider.changePassword();
    }

    // ✅ 3. Nếu thành công thì gọi lại AuthProvider để lấy user mới
    final success = profileSuccess && passwordSuccess;
    if (success) {
      await context.read<AuthProvider>().fetchAndSetUser();
    }

    // 4. Hiển thị kết quả
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? (success ? 'Cập nhật thành công!' : 'Cập nhật thất bại.')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }



  // ✅ HÀM MỚI ĐỂ XỬ LÝ VIỆC ĐỔI MẬT KHẨU
  Future<void> _changePassword() async {
    final isValid = _passwordFormKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final provider = context.read<EditProfileProvider>();
    final success = await provider.changePassword();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? (success ? 'Đổi mật khẩu thành công!' : 'Đổi mật khẩu thất bại.')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa Thông tin Cá nhân'),
        actions: [
          provider.isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2.5),
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Iconsax.save_2),
            onPressed: _saveProfile,
            tooltip: 'Lưu thay đổi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar section
              Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: provider.pickedImageFile != null
                          ? Image.file(File(provider.pickedImageFile!.path), fit: BoxFit.cover)
                          : (user?.avt_url != null && user!.avt_url.isNotEmpty)
                          ? Image.network(
                        _fixAvatarUrl(user.avt_url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Iconsax.user, size: 60, color: Colors.grey),
                      )
                          : const Icon(Iconsax.user, size: 60, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: IconButton(
                        icon: const Icon(Iconsax.camera, color: Colors.white, size: 20),
                        onPressed: provider.pickImage,
                      ),
                    ),
                  ),
                  if (provider.pickedImageFile != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(100)),
                        child: IconButton(
                          icon: const Icon(Iconsax.trash, color: Colors.white, size: 16),
                          onPressed: provider.clearImage,
                          tooltip: 'Xóa ảnh đã chọn',
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Họ và tên
              TextFormField(
                controller: provider.fullNameController,
                decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Iconsax.user)),
                validator: (value) {
                  if (value == null || value.trim().length < 2) return 'Họ tên phải có ít nhất 2 ký tự.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (read-only)
              TextFormField(
                initialValue: user?.email,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Iconsax.sms)),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Số điện thoại
              TextFormField(
                controller: provider.phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Iconsax.call)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Đổi mật khẩu (không tách riêng)
              TextFormField(
                controller: provider.currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: Icon(Iconsax.lock),
                ),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu hiện tại' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: provider.newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Iconsax.lock_1),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: provider.confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Iconsax.shield_tick),
                ),
                obscureText: true,
                validator: (v) {
                  if (v != provider.newPasswordController.text) return 'Mật khẩu xác nhận không khớp.';
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Nút lưu tất cả
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading || provider.isPasswordSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: provider.isLoading || provider.isPasswordSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
