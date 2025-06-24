// file: lib/screens/admin/pages/product_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../../providers/product_admin_provider.dart';
import '../../../models/admin/product_admin_model.dart';
import 'package:fashion_store_app/screens/admin/pages/add_edit_product_screen.dart';
// import 'package:fashion_store_app/models/admin/product_admin_model.dart'; // Import này bị trùng, có thể xóa

// ĐỊNH NGHĨA BASE URL CHO BACKEND CỦA BẠN Ở ĐÂY
// Thay thế bằng URL thực tế của backend bạn
// Ví dụ cho Android Emulator nếu backend chạy ở localhost:8080 trên máy host:
const String backendBaseUrl = "http://10.0.2.2:8080/";
// Ví dụ cho iOS Simulator hoặc Flutter Web nếu backend chạy ở localhost:8080:
// const String backendBaseUrl = "http://localhost:8080";
// Ví dụ nếu backend đã deploy:
// const String backendBaseUrl = "https://api.yourfashionshop.com";


class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  // ... (các biến state và hàm initState, _loadProducts, dispose, v.v. giữ nguyên) ...
  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'id,desc';
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts(refresh: true);
    });
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
    if (loadMore && !refresh) setState(() { _isLoadingMore = true; });
    await provider.fetchProducts(
      page: _currentPage,
      size: _pageSize,
      sort: _currentSort,
      nameQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
    if (loadMore && !refresh) setState(() { _isLoadingMore = false; });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddEditScreen({ProductAdminModel? product}) async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (context) => AddEditProductScreen(product: product),
    ));
    if (result == true) _loadProducts(refresh: true);
  }

  void _confirmDeleteProduct(ProductAdminModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" (ID: ${product.id}) không? Hành động này không thể hoàn tác.'),
        actions: <Widget>[
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<ProductAdminProvider>(context, listen: false).deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Đã xóa sản phẩm "${product.name}"' : Provider.of<ProductAdminProvider>(context, listen: false).errorMessage ?? 'Lỗi xóa sản phẩm'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ProductAdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Quản lý sản phẩm"),
            centerTitle: true,
            backgroundColor: Colors.blue,
          ),
          body: Column(
            children: [
              // ... (Phần Search và Sort giữ nguyên) ...
              // const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm',
                          prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _loadProducts(refresh: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.search_status),
                      onPressed: () => _loadProducts(refresh: true),
                      tooltip: 'Tìm kiếm',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Iconsax.sort),
                      tooltip: "Sắp xếp",
                      onSelected: (String value) {
                        if (_currentSort != value) {
                          setState(() { _currentSort = value; });
                          _loadProducts(refresh: true);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: 'id,desc', child: Text('Mới nhất (ID giảm)')),
                        const PopupMenuItem<String>(value: 'id,asc', child: Text('Cũ nhất (ID tăng)')),
                        const PopupMenuItem<String>(value: 'name,asc', child: Text('Tên (A-Z)')),
                        const PopupMenuItem<String>(value: 'name,desc', child: Text('Tên (Z-A)')),
                        const PopupMenuItem<String>(value: 'price,asc', child: Text('Giá (Thấp đến Cao)')),
                        const PopupMenuItem<String>(value: 'price,desc', child: Text('Giá (Cao đến Thấp)')),
                      ],
                    ),
                  ],
                ),
              ),

              if (provider.isLoading && provider.products.isEmpty && provider.pageData == null)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.errorMessage != null && provider.products.isEmpty)
                Expanded(
                    child: Center( /* ... (Phần hiển thị lỗi giữ nguyên) ... */ )
                )
              else if (provider.products.isEmpty && !provider.isLoading)
                  const Expanded(child: Center(child: Text('Không có sản phẩm nào.', style: TextStyle(fontSize: 18, color: Colors.grey))))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadProducts(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 70),
                        itemCount: provider.products.length + ((provider.pageData?.last == false || _isLoadingMore) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.products.length) {
                            // ... (Logic nút "Tải thêm" giữ nguyên) ...
                            if (_isLoadingMore) {
                              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2,)));
                            } else if (provider.pageData?.last == false) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () => _loadProducts(loadMore: true),
                                    child: const Text("Tải thêm..."),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final product = provider.products[index];
                          String? displayImageUrl;

                          if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
                            if (product.imageUrl!.startsWith('http://') || product.imageUrl!.startsWith('https://')) {
                              // Nếu imageUrl đã là URL đầy đủ
                              displayImageUrl = product.imageUrl!;
                            } else {
                              // Nếu imageUrl là path tương đối (ví dụ: /images/products/filename.jpg)
                              // Backend của bạn trả về product.imageUrl là "/images/products/puma_rsx.jpg" phải không?
                              // Nếu đúng vậy, thì việc ghép trực tiếp là đúng:
                              // displayImageUrl = backendBaseUrl + product.imageUrl!;

                              // TUY NHIÊN, nếu product.imageUrl từ backend trả về chỉ là "puma_rsx.jpg" (không có /images/products/ ở đầu)
                              // thì bạn cần ghép như sau:
                              // displayImageUrl = backendBaseUrl + "/images/products/" + product.imageUrl!;

                              // HÃY KIỂM TRA GIÁ TRỊ product.imageUrl MÀ BACKEND TRẢ VỀ CHO BẠN
                              // Giả sử backend trả về product.imageUrl là "/images/products/puma_rsx.jpg"
                              if (product.imageUrl!.startsWith('/')) {
                                displayImageUrl = backendBaseUrl + product.imageUrl!;
                              } else {
                                // Nếu product.imageUrl chỉ là "puma_rsx.jpg"
                                displayImageUrl = "$backendBaseUrl/images/products/${product.imageUrl!}";
                              }
                              // print("Constructed Image URL: $displayImageUrl"); // Thêm dòng này để debug
                            }
                          }
                          // ***** KẾT THÚC THAY ĐỔI ĐỂ GHÉP BASEURL *****

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              leading: SizedBox(
                                width: 50, height: 50,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: displayImageUrl != null // << SỬ DỤNG displayImageUrl đã xử lý
                                      ? Image.network(
                                    displayImageUrl, // << SỬ DỤNG displayImageUrl đã xử lý
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, st) => Container(color: Colors.grey[200], child: const Icon(Iconsax.gallery_slash, size: 24, color: Colors.grey)),
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator(strokeWidth: 2, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                                    },
                                  )
                                      : Container(color: Colors.grey[200], child: const Icon(Iconsax.box_1, size: 24, color: Colors.grey)),
                                ),
                              ),
                              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${product.id} - Giá: ${product.price?.toStringAsFixed(0) ?? "N/A"} VND', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                  Text('Kho: ${product.stock ?? "N/A"} - Phổ biến: ${product.isPopular == true ? "Có" : "Không"}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Iconsax.edit, color: Theme.of(context).primaryColor, size: 20),
                                    tooltip: 'Sửa',
                                    onPressed: () => _navigateToAddEditScreen(product: product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Iconsax.trash, color: Colors.redAccent, size: 20),
                                    tooltip: 'Xóa',
                                    onPressed: () => _confirmDeleteProduct(product),
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToAddEditScreen(product: product),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              if (provider.pageData != null && provider.pageData!.totalElements > 0)
                Padding(
                  // ... (Phần thông tin phân trang giữ nguyên) ...
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trang: ${(provider.pageData!.number) + 1} / ${provider.pageData!.totalPages}', style: const TextStyle(fontSize: 12)),
                      Text('Tổng: ${provider.pageData!.totalElements} sản phẩm', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            // ... (FAB giữ nguyên) ...
            onPressed: () => _navigateToAddEditScreen(),
            tooltip: 'Thêm Sản phẩm Mới',
            icon: const Icon(
              Iconsax.add,
              color: Colors.white,
            ),
            label: const Text(
              "Thêm mới",
              style: TextStyle(color: Colors.white),
            ),

            backgroundColor:Colors.blue,

          ),
        );
      },
    );
  }
}