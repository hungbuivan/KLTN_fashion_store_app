// file: lib/widgets/popular_section.dart
import 'package:fashion_store_app/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/popular_item.dart';
import '../../widgets/navigation_menu.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import 'package:iconsax/iconsax.dart';

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
    // ... (logic fetch giữ nguyên)
    final url = Uri.parse('http://10.0.2.2:8080/api/products/popular');
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await http.get(url);
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonData = jsonDecode(utf8.decode(response.bodyBytes));
          final List<PopularItem?> tempList = jsonData.map((itemJson) => PopularItem.fromJson(itemJson as Map<String, dynamic>)).toList();
          setState(() { _popularItems = tempList.whereType<PopularItem>().toList(); _isLoading = false; });
        } else {
          setState(() { _errorMessage = 'Failed to load popular items. Status: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) { setState(() { _errorMessage = 'Error fetching data: $e'; _isLoading = false; });}
    }
  }

  String fixImageUrl(String? url) {
    // ... (logic fixImageUrl giữ nguyên)
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (url.contains('://localhost:8080')) return url.replaceFirst('://localhost:8080', 'http://10.0.2.2:8080');
      return url;
    }
    return 'http://10.0.2.2:8080/images/products/$url';
  }

  @override
  Widget build(BuildContext context) {
    // ... (phần build UI của PopularSection giữ nguyên) ...
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)));
    if (_popularItems.isEmpty) return const Center(child: Text('No popular items found.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Popular Items", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NavigationMenu(selectedIndex: 1))),
                child: Text("View All", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: _popularItems.map((item) => _buildPopularItemCard(context, item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularItemCard(BuildContext context, PopularItem item) {
    final authProvider = context.watch<AuthProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartProviderActions = context.read<CartProvider>();


    int currentProductId = item.id;
    bool canInteract = true;



    final bool isCurrentlyFavorite = canInteract ? wishlistProvider.isProductInWishlist(currentProductId) : false;

    const double cardWidth = 160.0;
    const double cardHeight = 260.0; // Chiều cao cố định cho card

    return GestureDetector(
      onTap: () {
        if (!canInteract) { /* ... */ return; }
        Navigator.pushNamed(context, '/product-detail', arguments: {'productId': currentProductId});
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 3),) ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect( // ✅ Đặt ClipRRect ở ngoài AspectRatio
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio( // ✅ Sử dụng AspectRatio để kiểm soát tỷ lệ
                  aspectRatio: 1 / 1, // Ví dụ: ảnh vuông (chiều rộng = chiều cao)
                  // Bạn có thể thử 4/5 hoặc 3/4 cho ảnh hơi cao hơn
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Positioned.fill(
                        child: (item.imageUrl.isNotEmpty)
                            ? Image.network(
                          fixImageUrl(item.imageUrl),
                          fit: BoxFit.cover, // Cover sẽ lấp đầy AspectRatio
                          errorBuilder: (ctx, err, st) => Container(color: Colors.grey[200], child: Icon(Iconsax.gallery_slash, color: Colors.grey[400], size: 30)),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator(strokeWidth: 2, value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
                          },
                        )
                            : Container(color: Colors.grey[200], child: Icon(Iconsax.gallery_add, color: Colors.grey[400], size: 40)),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: IconButton( /* ... Nút yêu thích ... */ icon: Icon(isCurrentlyFavorite ? Iconsax.heart5 : Iconsax.heart, color: isCurrentlyFavorite ? Colors.redAccent : Colors.black54, shadows: const [Shadow(color: Colors.white54, blurRadius: 4)],), iconSize: 22, splashRadius: 18, tooltip: isCurrentlyFavorite ? 'Xóa khỏi Yêu thích' : 'Thêm vào Yêu thích', onPressed: !canInteract ? null : () async { if (authProvider.isGuest) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng chức năng này.'))); return; } final wishlistActions = context.read<WishlistProvider>(); if (isCurrentlyFavorite) { await wishlistActions.removeFromWishlist(currentProductId); } else { await wishlistActions.addToWishlist(currentProductId); } },),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column( /* ... Thông tin sản phẩm và nút Add to Cart ... */ mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text( item.name ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), maxLines: 2, overflow: TextOverflow.ellipsis, ), Text( item.price != null ? currencyFormatter.format(item.price) : "N/A", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14), ), SizedBox( width: double.infinity, height: 36, child: ElevatedButton.icon( onPressed: !canInteract || authProvider.isLoading ? null : () async { if (authProvider.isGuest) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng.')), ); return; } final cartActions = context.read<CartProvider>(); final success = await cartActions.addItemToCart(currentProductId, 1); if (context.mounted) { if (success) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Đã thêm "${item.name}" vào giỏ hàng!'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)), ); } else { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(cartActions.errorMessage ?? 'Lỗi khi thêm vào giỏ hàng.'), backgroundColor: Colors.redAccent), ); } } }, icon: authProvider.isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Iconsax.shopping_bag, size: 16), label: authProvider.isLoading ? const SizedBox.shrink() : const Text('Add', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom( backgroundColor: Colors.black87, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tapTargetSize: MaterialTapTargetSize.shrinkWrap, ), ), ), ], ), ),
            ),
          ],
        ),
      ),
    );
  }
}
