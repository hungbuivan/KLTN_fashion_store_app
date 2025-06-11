// file: lib/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  static const routeName = '/edit-profile'; // Đặt tên cho route

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sửa Thông tin Cá nhân'),
      ),
      body: const Center(
        child: Text('Giao diện sửa thông tin sẽ được phát triển ở đây.'),
      ),
    );
  }
}