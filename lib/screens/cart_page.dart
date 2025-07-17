// file: lib/screens/cart_page.dart
// Cho utf8.decode
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../models/cart_model.dart';
import '../providers/bottom_nav_provider.dart'; // ✅ Import BottomNavProvider
import '../providers/cart_provider.dart';
import '../models/cart_item_model.dart';
import 'package:fashion_store_app/utils/formatter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // Chỉ fetch nếu cart là null (tức là chưa fetch lần nào hoặc đã bị clear)
      // và không đang trong quá trình loading.
      if (cartProvider.cart == null && !cartProvider.isLoading) {
        cartProvider.fetchCart();
      }
    });
  }

  // ✅ THÊM HÀM fixImageUrl VÀO ĐÂY
  String _fixImageUrl(String? originalUrlFromApi) {
    const String baseUrl = 'http://10.0.2.2:8080';

    if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
      return ''; // hoặc trả về ảnh mặc định
    }

    if (originalUrlFromApi.startsWith('http://') || originalUrlFromApi.startsWith('https://')) {
      // Nếu là localhost thì thay bằng 10.0.2.2
      if (originalUrlFromApi.contains('://localhost:8080')) {
        return originalUrlFromApi.replaceFirst('://localhost:8080', baseUrl);
      }
      return originalUrlFromApi;
    }

    // Nếu là path nội bộ như /images/products/abc.jpg
    if (originalUrlFromApi.startsWith('/')) {
      return '$baseUrl$originalUrlFromApi';
    }

    // Nếu chỉ là tên file, ví dụ abc.jpg
    return '$baseUrl/images/products/$originalUrlFromApi';
  }



  void _updateQuantity(BuildContext context, CartItemModel item, int newQuantity) {
    if (newQuantity < 1) {
      _confirmRemoveItem(context, item);
      return;
    }
    Provider.of<CartProvider>(context, listen: false)
        .updateCartItemQuantity(item.productId, newQuantity)
        .then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Provider.of<CartProvider>(context, listen: false).errorMessage ?? 'Lỗi cập nhật số lượng.'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _confirmRemoveItem(BuildContext context, CartItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${item.productName}" khỏi giỏ hàng?'),
        actions: <Widget>[
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<CartProvider>(context, listen: false).removeItemFromCart(item.productId);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(Provider.of<CartProvider>(context, listen: false).errorMessage ?? 'Lỗi xóa sản phẩm.'), backgroundColor: Colors.red),
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
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng của bạn'),
        // ✅ CẬP NHẬT NÚT BACK
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black),
        //   onPressed: () {
        //     // Chuyển về tab Trang chủ (index 0) của BottomNavigationBar
        //     context.read<BottomNavProvider>().changeTab(0);
        //     // Sau đó pop màn hình CartPage hiện tại (nếu nó được push lên)
        //     if (Navigator.canPop(context)) {
        //       Navigator.of(context).pop();
        //     }
        //     // Nếu CartPage là một tab chính và không pop được,
        //     // việc changeTab ở trên đã đủ để chuyển về tab Home.
        //   },
        // ),
        actions: [
          if (cart != null && cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.trash),
              tooltip: 'Xóa tất cả',
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa toàn bộ Giỏ hàng?'),
                      content: const Text('Bạn có chắc chắn muốn xóa tất cả sản phẩm khỏi giỏ hàng?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
                        TextButton(
                            child: const Text('Xóa hết', style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await Provider.of<CartProvider>(context, listen: false).clearCart();
                              // SnackBar thông báo có thể thêm ở đây
                            }),
                      ],
                    ));
              },
            )
        ],
      ),
      body: _buildCartContent(context, cartProvider),
      bottomNavigationBar: cart != null && cart.items.isNotEmpty
          ? _buildCheckoutSection(context, cart)
          : null,
    );
  }

  Widget _buildCartContent(BuildContext context, CartProvider provider) {
    if (provider.isLoading && provider.cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.cart == null) {
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.warning_2, size: 50, color: Colors.redAccent),
                const SizedBox(height: 10),
                Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: ()=> provider.fetchCart(), child: const Text("Thử lại"))
              ],
            ),
          )
      );
    }
    if (provider.cart == null || provider.cart!.items.isEmpty) {
      return _buildEmptyCart(context);
    }

    final cartItems = provider.cart!.items;

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    // ✅ SỬA LỖI Ở ĐÂY
                    child: Image.network(_fixImageUrl(item.productImageUrl))


                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),

                      // ✅ THÊM WIDGET HIỂN THỊ SIZE/COLOR VÀO ĐÂY
                      if ((item.size != null && item.size!.isNotEmpty) || (item.color != null && item.color!.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            // Ghép chuỗi, chỉ hiển thị phần có giá trị
                            'Phân loại: ${item.color ?? ''}${ (item.color != null && item.size != null) ? ' / ' : '' }${item.size ?? ''}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ),

                      Text(
                        item.productPrice != null ? currencyFormatter.format(item.productPrice) : 'N/A',
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("SL: ", style: TextStyle(fontSize: 14, color: Colors.grey)),
                          SizedBox(
                            width: 30, height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Iconsax.minus_square, size: 20),
                              onPressed: item.quantity > 1 ? () => _updateQuantity(context, item, item.quantity - 1) : null,
                            ),
                          ),
                          Text(item.quantity.toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 30, height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Iconsax.add_square, size: 20, color: Colors.green),
                              onPressed: () => _updateQuantity(context, item, item.quantity + 1),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Iconsax.trash, color: Colors.redAccent.withOpacity(0.8), size: 22),
                  tooltip: 'Xóa sản phẩm',
                  onPressed: () => _confirmRemoveItem(context, item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    // ... (Giữ nguyên như trước, chỉ đảm bảo nút "Bắt đầu mua sắm" gọi đúng provider)
    final Color buttonColor = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/empty_cart.png', // 👈 THAY BẰNG ĐƯỜNG DẪN ẢNH CỦA BẠN
              // height: 150, // Điều chỉnh kích thước
              errorBuilder: (ctx, err, st) => Icon(Iconsax.box_remove, size: 100, color: Colors.grey[400]), // Fallback
            ),
            const SizedBox(height: 24),
            const Text(
              'Giỏ hàng của bạn trống trơn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'Có vẻ như bạn chưa thêm sản phẩm nào vào giỏ. Hãy bắt đầu mua sắm nào!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            // Chuyển tab về Trang chủ (index 0)
            context.read<BottomNavProvider>().changeTab(0);

            // Điều hướng về màn hình home, xóa các route trước đó
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
                  (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
          ),
          child: const Text('Bắt đầu mua sắm', style: TextStyle(color: Colors.white)),
        ),


          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(BuildContext context, CartModel cart) {
    // ... (Giữ nguyên như trước)
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0).copyWith(
        bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 4.0 : 20.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 0, blurRadius: 10, offset: const Offset(0,-3))],
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng (${cart.totalItems} sản phẩm):', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text(
                cart.cartTotalPrice != null ? currencyFormatter.format(cart.cartTotalPrice) : '0 VND',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                print('Tiến hành Thanh toán - Tổng tiền: ${cart.cartTotalPrice}');
                Navigator.pushReplacementNamed(context, '/checkout');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tiến hành Thanh toán'),
            ),
          ),
        ],
      ),
    );
  }
}
