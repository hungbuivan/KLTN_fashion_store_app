// file: lib/screens/product_detail_screen.dart
import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/product_detail_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/wishlist_provider.dart';

// TODO: Import màn hình xem tất cả review (ví dụ: all_reviews_screen.dart)
// import 'all_reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedColor;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductDetailProvider>(context, listen: false).clearProductDetails();
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
                onPressed: () => productProvider.fetchProductDetails(widget.productId),
              )
            ],
          ),
        ),
      )
          : product == null
          ? const Center(child: Text("Không có thông tin sản phẩm."))
          : _buildProductContent(context, product, wishlistProvider, authProvider),
      bottomNavigationBar: product != null ? _buildAddToCartButton(context, product) : null,
    );
  }

  Widget _buildProductContent(
      BuildContext context,
      ProductDetailModel product,
      WishlistProvider wishlistProvider,
      AuthProvider authProvider) {

    if (_selectedColor == null && product.availableColors.isNotEmpty) {
      _selectedColor = product.availableColors[0];
      print('Init selected color: $_selectedColor');
    }
    if (_selectedSize == null && product.availableSizes.isNotEmpty) {
      _selectedSize = product.availableSizes[0];
      print('Init selected size: $_selectedSize');
    }

    final bool isFavorite = wishlistProvider.isProductInWishlist(product.id);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.4,
          pinned: true,
          stretch: true,
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[800]),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Iconsax.share, color: Colors.grey[800]),
              tooltip: 'Chia sẻ',
              onPressed: () {
                print('Share product: ${product.name}');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng chia sẻ đang được phát triển!')),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                ? Hero(
              tag: 'product_image_${product.id}',
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (ctx, err, st) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Iconsax.gallery_slash, size: 80, color: Colors.grey))
                ),
                loadingBuilder: (ctx, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      )
                  );
                },
              ),
            )
                : Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Iconsax.gallery_slash, size: 80, color: Colors.grey)),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ HIỂN THỊ ĐÁNH GIÁ Ở ĐÂY
                // Widget _buildRatingAndReviews sẽ chỉ hiển thị nếu có dữ liệu hợp lệ
                _buildRatingAndReviews(context, product), // Truyền context
                if (product.averageRating != null && product.averageRating! > 0 && product.totalReviews != null && product.totalReviews! > 0)
                  const SizedBox(height: 16), // Khoảng cách sau phần rating

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.grey[100],
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          if (authProvider.isGuest) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để yêu thích sản phẩm.')));
                            return;
                          }
                          final wishlistProviderActions = context.read<WishlistProvider>();
                          if (isFavorite) {
                            print('Remove from wishlist product id: ${product.id}');
                            await wishlistProviderActions.removeFromWishlist(product.id);
                          } else {
                            print('Add to wishlist product id: ${product.id}');
                            await wishlistProviderActions.addToWishlist(product.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            isFavorite ? Iconsax.heart5 : Iconsax.heart,
                            color: isFavorite ? Colors.redAccent : Colors.grey[600],
                            size: 26,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                _buildPrice(context, product),
                const SizedBox(height: 24),

                if (product.availableColors.isNotEmpty) ...[
                  _buildSectionTitle(context, "Màu sắc", selectedValue: _selectedColor),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    context: context,
                    choices: product.availableColors,
                    selectedChoice: _selectedColor,
                    onSelected: (value) {
                      print('Selected color: $value');
                      setState(() { _selectedColor = value; });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                if (product.availableSizes.isNotEmpty) ...[
                  _buildSectionTitle(context, "Kích thước", selectedValue: _selectedSize, trailingText: "Bảng size", onTrailingTap: () {
                    print("View Size Chart tapped");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng xem bảng size đang được phát triển!')),
                    );
                  }),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    context: context,
                    choices: product.availableSizes,
                    selectedChoice: _selectedSize,
                    onSelected: (value) {
                      print('Selected size: $value');
                      setState(() { _selectedSize = value; });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                if (product.description != null && product.description!.isNotEmpty) ...[
                  Text("Mô tả sản phẩm", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    product.description!,
                    style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.6),
                  ),
                  const SizedBox(height: 20),
                ],

                if (product.stock != null)
                  Row(
                    children: [
                      const Text("Tồn kho:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Text(
                        product.stock! > 0 ? product.stock!.toString() : "Hết hàng",
                        style: TextStyle(
                          fontSize: 16,
                          color: product.stock! > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingAndReviews(BuildContext context, ProductDetailModel product) {
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
          const SnackBar(content: Text('Chức năng xem tất cả đánh giá đang được phát triển!')),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "${product.totalReviews} đánh giá",
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPrice(BuildContext context, ProductDetailModel product) {
    return Text(
      "${product.price?.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} ₫",
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {String? selectedValue, String? trailingText, VoidCallback? onTrailingTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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

  Widget _buildAddToCartButton(BuildContext context, ProductDetailModel product) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng đăng nhập để mua hàng.')),
            );
          },
          child: const Text("Đăng nhập để mua hàng"),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: ElevatedButton.icon(
        icon: const Icon(Iconsax.shopping_cart),
        label: const Text("Thêm vào giỏ hàng"),
        onPressed: () {
          // TODO: Xử lý thêm vào giỏ hàng với màu, size đã chọn
          if (_selectedColor == null || _selectedSize == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vui lòng chọn màu sắc và kích thước trước khi thêm vào giỏ.')),
            );
            return;
          }
          print('Add to cart product id: ${product.id}, color: $_selectedColor, size: $_selectedSize');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sản phẩm đã được thêm vào giỏ hàng.')),
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}
