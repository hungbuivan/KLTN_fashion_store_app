
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: 5, // Tạm thời hiển thị 5 mục mẫu
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Iconsax.heart),
            title: Text('Product ${index + 1}'),
            subtitle: const Text('This is a sample favorite product.'),
            trailing: IconButton(
              icon: const Icon(Iconsax.trash),
              onPressed: () {
                // Xử lý xóa sản phẩm khỏi wishlist
              },
            ),
          );
        },
      ),
    );
  }
}
