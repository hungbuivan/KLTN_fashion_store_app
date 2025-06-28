// file: lib/screens/product_detail_screen.dart
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:carousel_slider/carousel_controller.dart' as cs;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../models/product_detail_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/add_to_cart_bottom_sheet.dart';
import 'package:fashion_store_app/utils/formatter.dart';

import '../../widgets/product_reviews_section.dart';
// TODO: Import màn hình xem tất cả review (ví dụ: all_reviews_screen.dart)
// import 'all_reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  static const routeName = '/product-detail'; // ✅ Thêm dòng này
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
// State cho carousel
  int _currentImageIndex = 0;
  final cs.CarouselSliderController _controller = cs.CarouselSliderController();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider
          .of<ProductDetailProvider>(context, listen: false)
          .clearProductDetails();
      Provider.of<ProductDetailProvider>(context, listen: false)
          .fetchProductDetails(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductDetailProvider>();
    final product = productProvider.product;
    final wishlistProvider = context.watch<WishlistProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: productProvider.isLoading && product == null
          ? const Center(child: CircularProgressIndicator())
          : productProvider.errorMessage != null && product == null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                productProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 17),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Iconsax.refresh),
                label: const Text("Thử lại"),
                onPressed: () =>
                    productProvider.fetchProductDetails(widget.productId),
              )
            ],
          ),
        ),
      )
          : product == null
          ? const Center(child: Text("Không có thông tin sản phẩm."))
          : _buildProductContent(
          context, product, wishlistProvider, authProvider),
      bottomNavigationBar: product != null ? _buildAddToCartButton(
          context, product) : null,
    );
  }

  // ✅ HÀM MỚI: Dán hàm này vào trong _ProductDetailScreenState
  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/600';
    if (url.startsWith('http')) {
      if (url.contains('://localhost:8080'))
        return url.replaceFirst('://localhost:8080', serverBase);
      return url;
    }
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/products/$url';
  }

  // ✅ HÀM MỚI: Dán hàm này vào trong _ProductDetailScreenState
  void _showAddToCartSheet(BuildContext context,
      ProductDetailModel product) async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để mua hàng.')));
      return;
    }
// ✅ THÊM DEBUG PRINT CUỐI CÙNG Ở ĐÂY
    print("----------------------------------------------------");
    print("DEBUG (ProductDetailScreen): Checking product before showing bottom sheet:");
    print("  - Product Name: ${product.name}");
    print("  - Available Sizes from Model: ${product.availableSizes}");
    print("  - Available Colors from Model: ${product.availableColors}");
    print("----------------------------------------------------");
    // Nếu sản phẩm không có tùy chọn (size/color), thêm trực tiếp với số lượng 1
    if (product.availableSizes.isEmpty && product.availableColors.isEmpty) {
      final success = await cartProvider.addItemToCart(product.id, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Đã thêm "${product.name}" vào giỏ hàng!'
                : (cartProvider.errorMessage ?? 'Thêm vào giỏ hàng thất bại.')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      return;
    }

    // Ngược lại, hiển thị BottomSheet để người dùng chọn
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddToCartBottomSheet(product: product),
    );

    // Xử lý kết quả trả về từ BottomSheet
    if (result != null && mounted) {
      final int quantity = result['quantity'];
      final String? size = result['size'];
      final String? color = result['color'];

      // Gọi hàm addItemToCart của CartProvider với đầy đủ thông tin
      final success = await cartProvider.addItemToCart(
        product.id,
        quantity,
        size: size,
        color: color,
      );

      // Hiển thị SnackBar thông báo kết quả
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${product.name} (Size: ${size ??
                'N/A'}, Màu: ${color ?? 'N/A'}, SL: $quantity) vào giỏ hàng.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              cartProvider.errorMessage ?? 'Thêm vào giỏ hàng thất bại.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ THAY THẾ HÀM NÀY
  Widget _buildProductContent(BuildContext context,
      ProductDetailModel product,
      WishlistProvider wishlistProvider,
      AuthProvider authProvider) {
    final bool isFavorite = wishlistProvider.isProductInWishlist(product.id);

    return CustomScrollView(
      slivers: <Widget>[
        _buildSliverAppBar(context, product, authProvider, isFavorite),
        _buildSliverBody(context, product),
      ],
    );
  }

  // ✅ HÀM NÀY ĐÃ ĐƯỢC CẬP NHẬT HOÀN TOÀN
  SliverAppBar _buildSliverAppBar(BuildContext context, ProductDetailModel product, AuthProvider authProvider, bool isFavorite) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isFavorite = wishlistProvider.isProductInWishlist(product.id);

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.55,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[800]),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(icon: Icon(Iconsax.share, color: Colors.grey[800]), onPressed: () {}),
        IconButton(
          icon: Icon(isFavorite ? Iconsax.heart5 : Iconsax.heart, color: isFavorite ? Colors.redAccent : Colors.grey[800]),
          onPressed: () async {
            if (authProvider.isGuest) { return; }
            await context.read<WishlistProvider>().toggleWishlistItem(product.id);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Sử dụng CarouselSlider để hiển thị nhiều ảnh
            if (product.imageUrls.isNotEmpty)
              Hero(
                tag: 'product_image_${product.id}',
                child: cs.CarouselSlider.builder(
                  carouselController: _controller,
                  itemCount: product.imageUrls.length,
                  itemBuilder: (context, index, realIndex) {
                    return Image.network(
                      _fixImageUrl(product.imageUrls[index]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, e, s) => const Center(child: Icon(Iconsax.gallery_slash, size: 80, color: Colors.grey)),
                    );
                  },
                  options: cs.CarouselOptions(
                    height: MediaQuery.of(context).size.height * 0.6,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: product.imageUrls.length > 1,
                    onPageChanged: (index, reason) => setState(() => _currentImageIndex = index),
                  ),
                ),
              )
            else
              Container(color: Colors.grey[200], child: const Center(child: Icon(Iconsax.gallery_slash, size: 80, color: Colors.grey))),

            // Chỉ báo chấm tròn cho carousel
            if (product.imageUrls.length > 1)
              Positioned(
                bottom: 20.0,
                child: AnimatedSmoothIndicator(
                  activeIndex: _currentImageIndex,
                  count: product.imageUrls.length,
                  effect: ExpandingDotsEffect(
                    dotHeight: 8, dotWidth: 8,
                    activeDotColor: Theme.of(context).primaryColor,
                    dotColor: Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverBody(BuildContext context, ProductDetailModel product) {
    // ... (logic của hàm này giữ nguyên như trước)
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.brandName ?? product.categoryName ?? 'Thương hiệu', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(currencyFormatter.format(product.price ?? 0), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            const Divider(height: 40),
            if (product.description != null && product.description!.isNotEmpty) ...[
              Text("Mô tả sản phẩm", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(product.description!, style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6)),

              // ✅ THÊM DÒNG NÀY ĐỂ HIỂN THỊ PHẦN ĐÁNH GIÁ
              ProductReviewsSection(product: product),

            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingAndReviews(BuildContext context,
      ProductDetailModel product) {
    if (product.averageRating == null || product.totalReviews == null) {
      return const SizedBox.shrink();
    }
    if (product.averageRating! <= 0 || product.totalReviews! <= 0) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        print('View all reviews tapped for product id: ${product.id}');
        // TODO: Điều hướng sang màn hình xem tất cả đánh giá nếu có:
        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => AllReviewsScreen(productId: product.id)));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              'Chức năng xem tất cả đánh giá đang được phát triển!')),
        );
      },
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  product.averageRating!.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${product.totalReviews} đánh giá",
            style: TextStyle(
                color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPrice(BuildContext context, ProductDetailModel product) {
    return Text(
      "${product.price?.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} ₫",
      style: Theme
          .of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {String? selectedValue, String? trailingText, VoidCallback? onTrailingTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme
            .of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w600)),
        if (trailingText != null)
          InkWell(
            onTap: onTrailingTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(trailingText,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ),
      ],
    );
  }

  Widget _buildChoiceChips({
    required BuildContext context,
    required List<String> choices,
    required String? selectedChoice,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      children: choices.map((choice) {
        final bool isSelected = choice == selectedChoice;
        return ChoiceChip(
          label: Text(choice),
          selected: isSelected,
          selectedColor: Colors.redAccent.shade100,
          backgroundColor: Colors.grey.shade200,
          onSelected: (_) => onSelected(choice),
          labelStyle: TextStyle(
            color: isSelected ? Colors.redAccent : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // ✅ THAY THẾ TOÀN BỘ HÀM NÀY
  Widget _buildAddToCartButton(BuildContext context,
      ProductDetailModel product) {
    // Lấy trạng thái loading từ CartProvider
    final isCartLoading = context
        .watch<CartProvider>()
        .isLoading;

    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery
          .of(context)
          .padding
          .bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: ElevatedButton.icon(
        icon: isCartLoading
            ? Container(width: 20, height: 20, padding: const EdgeInsets.all(
            2.0), child: const CircularProgressIndicator(color: Colors.white,
            strokeWidth: 3))
            : const Icon(Iconsax.shopping_bag),
        label: Text(isCartLoading ? 'Đang thêm...' : 'Thêm vào giỏ hàng'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        // Sửa onPressed để gọi hàm hiển thị BottomSheet
        onPressed: (product.stock ?? 0) > 0 && !isCartLoading
            ? () => _showAddToCartSheet(context, product)
            : null, // Disable nếu hết hàng hoặc đang loading
      ),
    );
  }
}