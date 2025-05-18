import 'package:fashion_store_app/widgets/navigation_menu.dart';
import 'package:flutter/material.dart';
import 'package:fashion_store_app/widgets/all_product.dart';
import 'package:fashion_store_app/widgets/popular_selection.dart';
import 'package:fashion_store_app/views/home/app_header.dart';
import 'package:fashion_store_app/views/home/search_area.dart';
import 'package:fashion_store_app/widgets/categories_part.dart';
import 'package:fashion_store_app/widgets/banner_slider.dart';
import '../../core/theme/constant.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: width(context),
          height: height(context),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeader(),
                SearchArea(),
                CategoriesPart(),
                const SizedBox(height: 10),
                BannerSlider(),
                const SizedBox(height: 20),
                PopularSection(),
                AllProducts(),
               // NavigationMenu()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
