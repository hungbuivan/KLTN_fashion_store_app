// file: lib/widgets/home/popular_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Import các provider, model và widget cần thiết
import '../../providers/product_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
// Để chuyển tab
import '../../models/product_summary_model.dart';
import '../../utils/formatter.dart';
import '../views/home/product_details_screen.dart';
import 'add_to_cart_bottom_sheet.dart';
import 'navigation_menu.dart';

class PopularSection extends StatefulWidget {
  const PopularSection({super.key});

  @override
  State<PopularSection> createState() => _PopularSectionState();
}

class _PopularSectionState extends State<PopularSection> {

  @override
  void initState() {
    super.initState();
    // Gọi provider để tải dữ liệu khi widget được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Chỉ tải nếu danh sách đang rỗng để tránh gọi API không cần thiết
      if (context.read<ProductProvider>().popularProducts.isEmpty) {
        context.read<ProductProvider>().fetchPopularProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sản phẩm phổ biến", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NavigationMenu(selectedIndex: 1),
                      ),
                    );

                },
                child: const Text("Xem tất cả"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sử dụng Consumer để lắng nghe và rebuild khi có dữ liệu mới
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            if (provider.isLoadingPopular && provider.popularProducts.isEmpty) {
              return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
            }
            if (provider.errorPopularMessage != null) {
              return SizedBox(height: 150, child: Center(child: Text(provider.errorPopularMessage!)));
            }
            if (provider.popularProducts.isEmpty) {
              return const SizedBox(height: 150, child: Center(child: Text("Không có sản phẩm phổ biến.")));
            }

            return SizedBox(
              height: 250, // Tăng chiều cao để có không gian cho nút
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.popularProducts.length,
                itemBuilder: (context, index) {
                  final product = provider.popularProducts[index];
                  return ProductPopularCard(product: product);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// Widget riêng cho mỗi card sản phẩm
class ProductPopularCard extends StatelessWidget {
  final ProductSummaryModel product;
  const ProductPopularCard({super.key, required this.product});

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/300';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase$url';
  }

  // Hàm hiển thị BottomSheet để chọn size/color
  void _showAddToCartSheet(BuildContext context) async {
    final detailProvider = context.read<ProductDetailProvider>();
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để mua hàng.')));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    await detailProvider.fetchProductDetails(product.id);
    Navigator.of(context).pop(); // Đóng dialog loading

    if (!context.mounted) return;

    final productDetail = detailProvider.product;
    if (productDetail == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(detailProvider.errorMessage ?? 'Không thể tải chi tiết sản phẩm.')));
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddToCartBottomSheet(product: productDetail),
    );

    if (result != null && context.mounted) {
      final success = await cartProvider.addItemToCart(product.id, result['quantity'], size: result['size'], color: result['color']);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Đã thêm vào giỏ hàng!' : (cartProvider.errorMessage ?? 'Thêm thất bại.')), backgroundColor: success ? Colors.green : Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final authProvider = context.read<AuthProvider>();
    final bool isFavorite = wishlistProvider.isProductInWishlist(product.id);

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Ảnh sản phẩm + điều hướng chi tiết
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          ProductDetailScreen.routeName,
                          arguments: {'productId': product.id},
                        );
                      },
                      child: Hero(
                        tag: 'product_image_${product.id}',
                        child: Image.network(
                          _fixImageUrl(product.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Icon(
                            Iconsax.gallery_slash,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ❤️ Nút yêu thích mới (không có nền trắng, có shadow nhẹ)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Iconsax.heart5 : Iconsax.heart,
                          color: isFavorite ? Colors.redAccent : Colors.black54,
                          shadows: const [Shadow(color: Colors.white54, blurRadius: 4)],
                        ),
                        iconSize: 22,
                        splashRadius: 18,
                        tooltip: isFavorite ? 'Xóa khỏi Yêu thích' : 'Thêm vào Yêu thích',
                        onPressed: () async {
                          if (authProvider.isGuest) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng chức năng này.')),
                            );
                            return;
                          }

                          final wishlistProvider = context.read<WishlistProvider>();
                          if (isFavorite) {
                            await wishlistProvider.removeFromWishlist(product.id);
                          } else {
                            await wishlistProvider.addToWishlist(product.id);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Phần tên, giá và nút Mua
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product.price ?? 0),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 🛒 Nút Mua giống AllProduct
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: authProvider.isGuest
                          ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng.')),
                        );
                      }
                          : () => _showAddToCartSheet(context),
                      icon: const Icon(Iconsax.shopping_bag, size: 16),
                      label: const Text('Mua', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
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
          ],
        ),
      ),
    );
  }
}
