import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/popular_item.dart';
import '../../widgets/navigation_menu.dart';
// Model PopularItem


class PopularSection extends StatefulWidget {
  const PopularSection({super.key});

  @override
  State<PopularSection> createState() => _PopularSectionState();
}

class _PopularSectionState extends State<PopularSection> {
  List<PopularItem> _popularItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPopularItems();

  }

  Future<void> _fetchPopularItems() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/products/popular');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _popularItems = jsonData.map((itemJson) => PopularItem.fromJson(itemJson)).toList();
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load items. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  String fixImageUrl(String url) {
    if (!url.startsWith('http')) {
      return 'http://10.0.2.2:8080/images/products/$url';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)));
    }
    if (_popularItems.isEmpty) {
      return const Center(child: Text('No popular items found.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Popular Items + View All
        SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text(
                "Popular Items",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationMenu(selectedIndex: 1), // Mở Categories
                    ),
                  );
                },
                child: Text(
                  "View All",
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),

            ],
          ),
        ),
        const SizedBox(height: 10),

        // --- Danh sách sản phẩm popular
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _popularItems.map((item) => _buildPopularItemCard(item)).toList(),
          ),
        ),
      ],
    );
  }

  // --- Widget mỗi sản phẩm
  Widget _buildPopularItemCard(PopularItem item) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // --- Ảnh sản phẩm
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  fixImageUrl(item.imageUrl),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // --- Icon yêu thích (trên góc phải)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Thêm sản phẩm vào Wishlist
                    print('Favorite ${item.name}');
                  },
                  child: Icon(
                    item.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "\$${item.price.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                // --- Icon Add to Cart
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Thêm sản phẩm vào giỏ hàng
                        print('Add to cart ${item.name}');
                      },
                      icon: Icon(Icons.add_shopping_cart, size: 16),
                      label: Text('Add', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




}
