// file: lib/screens/products_by_category_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Import các provider và model cần thiết
import '../providers/products_by_category_provider.dart';
import '../models/product_summary_model.dart';
import '../utils/formatter.dart'; // Giả sử bạn có file này
import '../views/home/product_details_screen.dart';
//import 'product_detail_screen.dart'; // Để điều hướng đến chi tiết sản phẩm

class ProductsByCategoryScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ProductsByCategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  static const routeName = '/products-by-category';

  @override
  State<ProductsByCategoryScreen> createState() => _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 10;
  late ProductsByCategoryProvider _productProvider;
  @override
  void initState() {
    super.initState();
    // Gán provider tại thời điểm còn safe

    // Tải dữ liệu lần đầu tiên cho trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts(refresh: true);
      _productProvider = Provider.of<ProductsByCategoryProvider>(context, listen: false);
    });

    // Thêm listener để xử lý "tải thêm" khi cuộn xuống cuối
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // Dọn dẹp provider khi màn hình bị hủy
    _productProvider.clearProducts();
    super.dispose();
  }

  void _onScroll() {
    // Kiểm tra nếu người dùng đã cuộn gần đến cuối
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ProductsByCategoryProvider>(context, listen: false);
      // Chỉ tải thêm nếu không phải là trang cuối và không đang trong quá trình tải
      if (provider.pageData?.last == false && !_isLoadingMore) {
        _loadProducts(loadMore: true);
      }
    }
  }

  Future<void> _loadProducts({bool refresh = false, bool loadMore = false}) async {
    final provider = Provider.of<ProductsByCategoryProvider>(context, listen: false);

    if (refresh) {
      _currentPage = 0;
    } else if (loadMore) {
      _currentPage++;
    }

    if (loadMore && mounted) {
      setState(() { _isLoadingMore = true; });
    }

    await provider.fetchProductsByCategoryId(
      widget.categoryId,
      page: _currentPage,
      size: _pageSize,
    );

    if (loadMore && mounted) {
      setState(() { _isLoadingMore = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        elevation: 1,
        // TODO: Thêm các nút filter, sort nếu cần
      ),
      body: Consumer<ProductsByCategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(provider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(icon: const Icon(Iconsax.refresh), label: const Text("Thử lại"), onPressed: () => _loadProducts(refresh: true)),
                  ],
                ),
              ),
            );
          }
          if (provider.products.isEmpty) {
            return const Center(child: Text('Chưa có sản phẩm nào trong danh mục này.', style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return RefreshIndicator(
            onRefresh: () => _loadProducts(refresh: true),
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.7, // Điều chỉnh tỷ lệ để phù hợp với giao diện
              ),
              itemCount: provider.products.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.products.length) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                final product = provider.products[index];
                return ProductGridItem(product: product);
              },
            ),
          );
        },
      ),
    );
  }
}


// WIDGET HIỂN THỊ MỘT SẢN PHẨM TRONG LƯỚI
class ProductGridItem extends StatelessWidget {
  final ProductSummaryModel product;

  const ProductGridItem({super.key, required this.product});

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/300';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/products/$url';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          ProductDetailScreen.routeName,
          arguments: {'productId': product.id},
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'product_image_${product.id}',
                child: SizedBox(
                  width: double.infinity,
                  child: Image.network(
                    _fixImageUrl(product.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => const Icon(Iconsax.gallery_slash, color: Colors.grey, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product.price ?? 0),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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