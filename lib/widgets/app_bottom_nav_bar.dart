import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 80,
      elevation: 0,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(icon: Icon(Iconsax.home), label: "Trang chủ"),
        NavigationDestination(icon: Icon(Iconsax.category), label: "Danh mục"),
        NavigationDestination(icon: Icon(Iconsax.card_tick), label: "Giỏ hàng"),
        NavigationDestination(icon: Icon(Iconsax.heart), label: "Yêu thích"),
        NavigationDestination(icon: Icon(Iconsax.user), label: "Tài khoản"),
      ],
    );
  }
}
