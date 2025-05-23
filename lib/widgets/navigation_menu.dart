import 'package:fashion_store_app/screens/cart_page.dart';
import 'package:fashion_store_app/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'app_bottom_nav_bar.dart'; // nhớ import
import '../screens/category_page.dart';
import '../screens/home_page.dart';
import '../screens/account_page.dart';


class NavigationMenu extends StatefulWidget {
  final int selectedIndex;

  const NavigationMenu({super.key, this.selectedIndex = 0});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreens()[_currentIndex],
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      HomePage(),
      CategoryPage(),
      CartPage(),
      WishlistScreen(),
      AccountPage(),
    ];
  }
}
