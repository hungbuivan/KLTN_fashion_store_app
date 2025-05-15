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
        NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
        NavigationDestination(icon: Icon(Iconsax.category), label: "Categories"),
        NavigationDestination(icon: Icon(Iconsax.card_tick), label: "Cart"),
        NavigationDestination(icon: Icon(Iconsax.heart), label: "Wishlist"),
        NavigationDestination(icon: Icon(Iconsax.user), label: "Profile"),
      ],
    );
  }
}
