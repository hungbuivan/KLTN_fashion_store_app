// file: lib/widgets/all_product.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';


import 'package:fashion_store_app/providers/product_detail_provider.dart';
import 'package:fashion_store_app/providers/product_provider.dart';
import 'package:fashion_store_app/providers/wishlist_provider.dart';
import 'package:fashion_store_app/providers/cart_provider.dart';
import 'package:fashion_store_app/providers/auth_provider.dart';
import 'package:fashion_store_app/models/product_summary_model.dart';
// import '../screens/product_detail_screen.dart';
import 'package:fashion_store_app/views/home/product_details_screen.dart';
import 'package:fashion_store_app/widgets/add_to_cart_bottom_sheet.dart';
import 'package:fashion_store_app/utils/formatter.dart';
import 'package:fashion_store_app/widgets/navigation_menu.dart';


class AllProducts extends StatefulWidget {
  const AllProducts({super.key});

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProducts();
    });
    //_scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
   // _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
    //   final provider = Provider.of<ProductProvider>(context, listen: false);
    //   if (provider.pageData != null && !provider.pageData!.last && !provider.isLoading) {
    //     provider.fetchProducts(page: provider.pageData!.number + 1);
    //   }
    // }
  }

  Future<void> _refreshProducts() async {
    await Provider.of<ProductProvider>(context, listen: false).fetchProducts(page: 0, size: 1000);
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.products.isEmpty) {
          return Center(child: Text(provider.errorMessage!));
        }

        if (provider.products.isEmpty) {
          return const Center(child: Text('Không có sản phẩm nào.'));
        }

        // ✅ SỬA LẠI CẤU TRÚC Ở ĐÂY
        return RefreshIndicator(
          onRefresh: _refreshProducts,
          child: SingleChildScrollView( // Bọc toàn bộ bằng SingleChildScrollView
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thêm tiêu đề và nút "Xem tất cả"
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tất cả sản phẩm",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
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

                // GridView hiển thị sản phẩm
                GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  // Các thuộc tính này rất quan trọng khi GridView nằm trong SingleChildScrollView
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.products.length, // ✅ Không cần cộng thêm loading item
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    if (index == provider.products.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    final product = provider.products[index];
                    return ProductGridItem(product: product);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProductGridItem extends StatelessWidget {
  final ProductSummaryModel product;
  const ProductGridItem({super.key, required this.product});

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/300';
    if (url.startsWith('http')) {
      if (url.contains('://localhost:8080')) return url.replaceFirst('://localhost:8080', serverBase);
      return url;
    }
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase$url';
  }

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
    Navigator.of(context).pop();

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Đã thêm vào giỏ hàng!' : (cartProvider.errorMessage ?? 'Thêm thất bại.')),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final authProvider = context.read<AuthProvider>();
    final bool isFavorite = wishlistProvider.isProductInWishlist(product.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed(ProductDetailScreen.routeName, arguments: {'productId': product.id});
                    },
                    child: Hero(
                      tag: 'product_image_${product.id}',
                      child: Image.network(
                        _fixImageUrl(product.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => const Icon(Iconsax.gallery_slash, color: Colors.grey, size: 40),
                      ),
                    ),
                  ),
                ),
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
                        if (isFavorite) {
                          await context.read<WishlistProvider>().removeFromWishlist(product.id);
                        } else {
                          await context.read<WishlistProvider>().addToWishlist(product.id);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  product.price != null ? currencyFormatter.format(product.price) : 'N/A',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
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
    );
  }
}