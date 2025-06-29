// file: lib/screens/admin/pages/product_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// Import các provider, model và màn hình cần thiết
import '../../../providers/product_admin_provider.dart';
import '../../../models/admin/product_admin_model.dart';
import '../../../utils/formatter.dart';
import '../../screens/admin/pages/add_edit_product_screen.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'id,desc';
  int _currentPage = 0;
  final int _pageSize = 100;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProducts();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
    //   final provider = Provider.of<ProductAdminProvider>(context, listen: false);
    //   if (provider.pageData != null && !provider.pageData!.last && !_isLoadingMore) {
    //     _loadProducts(loadMore: true);
    //   }
    // }
  }

  Future<void> _loadProducts({bool refresh = false, bool loadMore = false}) async {
    final provider = Provider.of<ProductAdminProvider>(context, listen: false);
    if (refresh) {
      _currentPage = 0;
    } else if (loadMore) {
      if (provider.pageData != null && !provider.pageData!.last) {
        _currentPage++;
      } else {
        return;
      }
    }
    if (loadMore) setState(() { _isLoadingMore = true; });
    await provider.fetchProducts(
      page: _currentPage,
      size: _pageSize,
      sort: _currentSort,
      nameQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
    if (loadMore) setState(() { _isLoadingMore = false; });
  }

  Future<void> _refreshProducts() async {
    await _loadProducts(refresh: true);
  }

  void _navigateToAddEditScreen({ProductAdminModel? product}) async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (context) => AddEditProductScreen(product: product),
    ));
    if (result == true) _refreshProducts();
  }

  void _confirmDeleteProduct(ProductAdminModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" (ID: ${product.id}) không?'),
        actions: <Widget>[
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<ProductAdminProvider>(context, listen: false).deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Đã xóa sản phẩm "${product.name}"' : Provider.of<ProductAdminProvider>(context, listen: false).errorMessage ?? 'Lỗi xóa sản phẩm'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý sản phẩm")),
      body: Consumer<ProductAdminProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Tìm kiếm', prefixIcon: const Icon(Iconsax.search_normal_1, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true), onSubmitted: (_) => _refreshProducts())),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Iconsax.search_status), onPressed: () => _refreshProducts(), tooltip: 'Tìm kiếm'),
                    PopupMenuButton<String>(
                      icon: const Icon(Iconsax.sort),
                      tooltip: "Sắp xếp",
                      onSelected: (String value) {
                        if (_currentSort != value) { setState(() { _currentSort = value; }); _refreshProducts(); }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: 'id,desc', child: Text('Mới nhất')),
                        const PopupMenuItem<String>(value: 'id,asc', child: Text('Cũ nhất')),
                        const PopupMenuItem<String>(value: 'name,asc', child: Text('Tên (A-Z)')),
                        const PopupMenuItem<String>(value: 'price,desc', child: Text('Giá (Cao > Thấp)')),
                      ],
                    ),
                  ],
                ),
              ),
              if (provider.isLoading && provider.products.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.errorMessage != null && provider.products.isEmpty)
                Expanded(child: Center(child: Text(provider.errorMessage!)))
              else if (provider.products.isEmpty)
                  const Expanded(child: Center(child: Text('Không có sản phẩm nào.')))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshProducts,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: provider.products.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.products.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                          }
                          final product = provider.products[index];
                          return ProductManagementListItem(
                            product: product,
                            onEdit: () => _navigateToAddEditScreen(product: product),
                            onDelete: () => _confirmDeleteProduct(product),
                          );
                        },
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEditScreen(),
        tooltip: 'Thêm Sản phẩm Mới',
        icon: const Icon(Iconsax.add),
        label: const Text("Thêm mới"),
      ),
    );
  }
}

// WIDGET HIỂN THỊ MỘT SẢN PHẨM TRONG DANH SÁCH
class ProductManagementListItem extends StatelessWidget {
  final ProductAdminModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductManagementListItem({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/150';
    if (url.startsWith('http')) {
      if (url.contains('://localhost:8080')) return url.replaceFirst('://localhost:8080', serverBase);
      return url;
    }
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/products/$url';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SỬA LỖI Ở ĐÂY
    // Lấy ảnh đầu tiên từ danh sách imageUrls làm ảnh đại diện
    final String displayImageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: displayImageUrl.isNotEmpty
                ? Image.network(
                _fixImageUrl(displayImageUrl),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Iconsax.gallery_slash)
            )
                : Container(color: Colors.grey[200], child: const Icon(Iconsax.gallery)),
          ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giá: ${currencyFormatter.format(product.price ?? 0)}'),
            Text('Kho: ${product.stock ?? 0}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Iconsax.edit, color: Theme.of(context).primaryColor), onPressed: onEdit),
            IconButton(icon: const Icon(Iconsax.trash, color: Colors.redAccent), onPressed: onDelete),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
