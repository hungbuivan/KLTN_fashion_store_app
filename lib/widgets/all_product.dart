// file: lib/widgets/all_product.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../models/popular_item.dart'; // Hoặc model sản phẩm chung của bạn
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart'; // ✅ Import CartProvider
import 'package:fashion_store_app/utils/formatter.dart';

class AllProducts extends StatefulWidget {
  const AllProducts({super.key});

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  List<PopularItem> _allItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllItems();
  }

  Future<void> _fetchAllItems() async {
    final url = Uri.parse('http://10.0.2.2:8080/api/products');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http.get(url);
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
          final List<PopularItem?> tempList = jsonData
              .map((itemJson) => PopularItem.fromJson(itemJson as Map<String, dynamic>))
              .toList();
          setState(() {
            _allItems = tempList.whereType<PopularItem>().toList();
            _isLoading = false;
          });
          print("AllProducts: Đã parse và lọc được ${_allItems.length} sản phẩm.");
        } else {
          setState(() {
            _errorMessage = 'Failed to load products. Status code: ${response.statusCode} - ${response.body}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching products: $e';
          _isLoading = false;
        });
      }
      print("AllProducts: Lỗi fetchAllItems: $e");
    }
  }

  String fixImageUrl(String? originalUrlFromApi) {
    const String imageBaseUrl = 'http://10.0.2.2:8080/images/products/';
    if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
      return '';
    }
    if (originalUrlFromApi.startsWith('http://') || originalUrlFromApi.startsWith('https://')) {
      if (originalUrlFromApi.contains('://localhost:8080')) {
        return originalUrlFromApi.replaceFirst('://localhost:8080', '://10.0.2.2:8080');
      }
      return originalUrlFromApi;
    }
    return imageBaseUrl + originalUrlFromApi;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
      ));
    }
    if (_allItems.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 16.0, bottom: 8.0),
              child: Text(
                "All Products",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              padding: const EdgeInsets.all(8.0),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 0.60,
              ),
              itemCount: _allItems.length,
              itemBuilder: (context, index) {
                final item = _allItems[index];
                return _buildProductItemCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItemCard(BuildContext context, PopularItem item) {
    final authProvider = context.watch<AuthProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartProviderActions = context.read<CartProvider>(); // ✅ Lấy CartProvider actions

    int currentProductId = -1;
    bool canInteract = false;

    // Đảm bảo item.id là int. Nếu PopularItem.id của bạn là String, bạn cần parse.
    // Ví dụ: currentProductId = int.tryParse(item.id.toString()) ?? -1;
    // Hiện tại, giả sử item.id đã là int hoặc có thể ép kiểu trực tiếp.
    if (item.id is String) {
      currentProductId = int.tryParse(item.id as String) ?? -1;
    } else {
      currentProductId = (item.id as num).toInt();
    }
  
    canInteract = currentProductId != -1;
  
    final bool isCurrentlyFavorite = canInteract
        ? wishlistProvider.isProductInWishlist(currentProductId)
        : false;

    return GestureDetector(
      onTap: () {
        if (!canInteract) { /* ... (xử lý ID không hợp lệ) ... */ return; }
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: {'productId': currentProductId},
        );
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Positioned.fill(
                    child: (item.imageUrl.isNotEmpty)
                        ? Image.network( /* ... (Image.network như cũ) ... */ fixImageUrl(item.imageUrl), fit: BoxFit.cover, errorBuilder: (ctx, err, st) => Container(color: Colors.grey[200], child: Icon(Iconsax.gallery_slash, color: Colors.grey[400], size: 30)), loadingBuilder: (ctx, child, progress) { if (progress == null) return child; return Center(child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)); },)
                        : Container(color: Colors.grey[200], child: Icon(Iconsax.gallery_add, color: Colors.grey[400], size: 40)),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: IconButton( /* ... (Nút Yêu thích như cũ, sử dụng currentProductId) ... */ icon: Icon(isCurrentlyFavorite ? Iconsax.heart5 : Iconsax.heart, color: isCurrentlyFavorite ? Colors.redAccent : Colors.black54, shadows: const [Shadow(color: Colors.white54, blurRadius: 4)],), iconSize: 22, splashRadius: 18, tooltip: isCurrentlyFavorite ? 'Xóa khỏi Yêu thích' : 'Thêm vào Yêu thích', onPressed: !canInteract ? null : () async { if (authProvider.isGuest) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng chức năng này.'))); return; } final wishlistActions = context.read<WishlistProvider>(); if (isCurrentlyFavorite) { await wishlistActions.removeFromWishlist(currentProductId); } else { await wishlistActions.addToWishlist(currentProductId); } },),
                  )
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    Text(item.price != null ? currencyFormatter.format(item.price) : "N/A", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton.icon(
                        // ✅ CẬP NHẬT onPressed CHO NÚT ADD TO CART
                        onPressed: !canInteract ? null : () async {
                          if (authProvider.isGuest) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng.')),
                            );
                            // TODO: Cân nhắc điều hướng đến trang đăng nhập
                            // Navigator.pushNamed(context, '/login_input');
                            return;
                          }

                          // Gọi hàm thêm vào giỏ hàng từ CartProvider
                          // Giả sử thêm 1 sản phẩm mỗi lần nhấn
                          final success = await cartProviderActions.addItemToCart(currentProductId, 1);

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã thêm "${item.name}" vào giỏ hàng!'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(cartProviderActions.errorMessage ?? 'Lỗi khi thêm vào giỏ hàng.'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        icon: const Icon(Iconsax.shopping_bag, size: 16),
                        label: const Text('Add', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
