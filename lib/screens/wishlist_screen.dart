// file: lib/screens/wishlist_screen.dart
import 'package:fashion_store_app/views/home/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart'; // Cho icon
import '../providers/wishlist_provider.dart';
import '../utils/formatter.dart';
// Import ProductDetailScreen để điều hướng khi nhấn vào sản phẩm
// import 'product_detail_screen.dart'; // Bạn cần có màn hình này

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    // Tải wishlist khi màn hình được tạo, nếu chưa có dữ liệu
    // Provider có thể đã tự tải trong constructor nếu user đã đăng nhập
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      // Chỉ fetch nếu danh sách rỗng và không đang loading (tránh gọi thừa)
      if (wishlistProvider.wishlistItems.isEmpty && !wishlistProvider.isLoading) {
        wishlistProvider.fetchWishlist();
      }
    });
  }

  String _fixImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    if (imageUrl.startsWith('/images/products/')) {
      return 'http://10.0.2.2:8080$imageUrl';
    }
    return 'http://10.0.2.2:8080/images/products/$imageUrl';
  }


  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ WishlistProvider
    final wishlistProvider = context.watch<WishlistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Yêu thích'),
        // backgroundColor: Theme.of(context).colorScheme.primary, // Tùy chỉnh màu AppBar
        // foregroundColor: Colors.white,
      ),
      body: _buildWishlistContent(context, wishlistProvider),
    );
  }

  Widget _buildWishlistContent(BuildContext context, WishlistProvider provider) {
    if (provider.isLoading && provider.wishlistItems.isEmpty) {
      // Hiển thị loading indicator khi đang tải lần đầu và danh sách rỗng
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.wishlistItems.isEmpty) {
      // Hiển thị lỗi nếu có lỗi và danh sách rỗng
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Iconsax.refresh),
                label: const Text("Thử lại"),
                onPressed: () => provider.fetchWishlist(),
              )
            ],
          ),
        ),
      );
    }

    if (provider.wishlistItems.isEmpty) {
      // ✅ Hiển thị giao diện "trống rỗng" như hình ảnh bạn cung cấp
      return _buildEmptyWishlist(context);
    }

    // Hiển thị danh sách sản phẩm yêu thích
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: provider.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = provider.wishlistItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: SizedBox(
              width: 70,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: item.productImageUrl != null && item.productImageUrl!.isNotEmpty
                    ? Image.network(
                  'http://10.0.2.2:8080${item.productImageUrl!}', // ✅ đúng với local server Android Emulator
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Iconsax.gallery_slash, color: Colors.grey),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[200],
                  child: const Icon(Iconsax.box_1, color: Colors.grey),
                ),
              ),

            ),
            title: Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              item.productPrice != null
                  ? currencyFormatter.format(item.productPrice)
                  : 'N/A',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Iconsax.heart_remove, color: Colors.redAccent),
              tooltip: 'Xóa khỏi yêu thích',
              onPressed: () async {
                // Gọi hàm xóa từ provider
                final success = await Provider.of<WishlistProvider>(context, listen: false)
                    .removeFromWishlist(item.productId, wishlistItemIdToDelete: item.wishlistItemId);
                if (context.mounted && !success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(Provider.of<WishlistProvider>(context, listen: false).errorMessage ?? 'Lỗi khi xóa sản phẩm.'), backgroundColor: Colors.red),
                  );
                }
                // Danh sách sẽ tự cập nhật do provider gọi notifyListeners
              },
            ),
            onTap: () {
              // TODO: Điều hướng đến trang chi tiết sản phẩm
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.productId)));
              print('Tapped on product: ${item.productName}');
            },
          ),
        );
      },
    );
  }

  // Widget cho giao diện khi wishlist trống
  Widget _buildEmptyWishlist(BuildContext context) {
    final Color buttonColor = Colors.blue.shade600; // Lấy màu từ theme hoặc định nghĩa

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ✅ Hình ảnh/Icon (bạn có thể dùng Image.asset nếu có ảnh)
            // Icon(Iconsax.heart_slash, size: 100, color: Colors.grey[400]),
            // Thay bằng Image.asset nếu bạn có ảnh như trong mẫu
            Image.asset(
              'assets/images/empty.png', // 👈 THAY BẰNG ĐƯỜNG DẪN ẢNH CỦA BẠN
              // height: 150, // Điều chỉnh kích thước
              errorBuilder: (ctx, err, st) => Icon(Iconsax.box_remove, size: 100, color: Colors.grey[400]), // Fallback
            ),
            const SizedBox(height: 24),
            const Text(
              'Danh sách yêu thích trống', // "Your shopping list is empty"
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa thêm sản phẩm nào vào danh sách yêu thích.', // "You have not added any product to wishlist"
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Điều hướng đến trang chủ hoặc trang sản phẩm để mua sắm
                // Ví dụ: quay lại trang home (nếu wishlist là 1 tab của home)
                if (Navigator.canPop(context)) {
                  // Nếu WishlistScreen được push lên từ đâu đó (ví dụ HomePage), thì pop về.
                  // Hoặc nếu HomePage quản lý các tab, bạn có thể muốn chuyển tab.
                  // Giả sử HomePage là một route và có thể pop về đó.
                  Navigator.popUntil(context, ModalRoute.withName('/home'));
                  // Hoặc đơn giản là pop màn hình hiện tại nếu nó được push lên
                  Navigator.pop(context);
                } else {
                  // Nếu không pop được (ví dụ Wishlist là màn hình đầu tiên sau login),
                  // thì điều hướng đến trang chủ bằng named route.
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.white)), // "To shopping"
            ),
          ],
        ),
      ),
    );
  }
}
