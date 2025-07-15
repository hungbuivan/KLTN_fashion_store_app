// file: lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Import các provider và model cần thiết
import '../providers/order_provider.dart';
import '../models/order_summary_model.dart';
import '../providers/bottom_nav_provider.dart';
import 'package:fashion_store_app/utils/formatter.dart';
// Import các màn hình khác để điều hướng
import 'order_detail_screen.dart';


// Các hàm helper (bạn có thể đưa chúng vào file utils chung)
//final currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0, name: '');


String _fixImageUrl(String? originalUrlFromApi) {
  const String serverBase = "http://10.0.2.2:8080";
  if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
    return 'https://via.placeholder.com/150/CCCCCC/FFFFFF?Text=No+Image';
  }
  if (originalUrlFromApi.startsWith('http')) {
    if (originalUrlFromApi.contains('://localhost:8080')) {
      return originalUrlFromApi.replaceFirst('://localhost:8080', serverBase);
    }
    return originalUrlFromApi;
  }
  if (originalUrlFromApi.startsWith('/')) {
    return serverBase + originalUrlFromApi;
  }
  return '$serverBase/images/products/$originalUrlFromApi';
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  static const routeName = '/order-history'; // Đặt tên cho route

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<void> _fetchOrdersFuture;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;


  @override
  void initState() {
    super.initState();
    // Gán việc gọi API vào một Future để FutureBuilder sử dụng.
    // Điều này ngăn việc gọi lại API mỗi khi widget rebuild (ví dụ khi setState).
    _fetchOrdersFuture = _loadOrders();
  }

  Future<void> _loadOrders({bool loadMore = false}) async {
    if (_isLoadingMore && loadMore) return;

    setState(() {
      _isLoadingMore = loadMore;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final pageToFetch = loadMore ? _currentPage + 1 : 0;

    await orderProvider.fetchUserOrders(page: pageToFetch, size: 10);

    if (mounted) {
      setState(() {
        _currentPage = orderProvider.currentPage;
        _hasMore = orderProvider.hasNextPage;
        _isLoadingMore = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử Đơn hàng'),
        elevation: 1,
        // Nếu màn hình này được push lên từ Profile, AppBar sẽ tự có nút back.
        // Nếu nó là một tab chính, bạn có thể không cần nút back.
      ),
      body: FutureBuilder(
        future: _fetchOrdersFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _buildErrorState(context, 'Lỗi tải dữ liệu: ${snapshot.error}');
          } else {
            return Consumer<OrderProvider>(
              builder: (ctx, orderProvider, child) {
                if (orderProvider.isLoading && orderProvider.userOrders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orderProvider.errorMessage != null && orderProvider.userOrders.isEmpty) {
                  return _buildErrorState(context, orderProvider.errorMessage!);
                }

                if (orderProvider.userOrders.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: () => _loadOrders(), // Tải lại từ trang đầu
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: orderProvider.userOrders.length + (_hasMore ? 1 : 0), // +1 nếu còn trang
                    itemBuilder: (context, index) {
                      if (index < orderProvider.userOrders.length) {
                        final order = orderProvider.userOrders[index];
                        return _buildOrderItemCard(context, order);
                      } else {
                        // 👉 Hiển thị nút Tải thêm hoặc Progress khi còn trang
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: _isLoadingMore
                                ? const CircularProgressIndicator()
                                : ElevatedButton.icon(
                              onPressed: () => _loadOrders(loadMore: true),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tải thêm'),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );

              },
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, OrderSummaryModel order) {
    final statusInfo = _getStatusInfo(order.status);
    final orderProvider = context.read<OrderProvider>();
    // ✅ KIỂM TRA ĐIỀU KIỆN ĐỂ HIỂN THỊ NÚT
    // Nút "Mua lại" chỉ hiện với các đơn hàng đã giao, hoàn thành, hoặc đã hủy.
    final bool canRepurchase = ['COMPLETED', 'DELIVERED', 'CANCELLED_BY_USER', 'CANCELLED_BY_ADMIN'].contains(order.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Sử dụng pushNamed để điều hướng đến chi tiết đơn hàng
          Navigator.of(context).pushNamed(
            OrderDetailScreen.routeName, // Sử dụng routeName đã định nghĩa
            arguments: {'orderId': order.orderId}, // Truyền orderId qua arguments
          ).then((_) {
            // Sau khi quay lại từ OrderDetailScreen, tải lại danh sách đơn hàng
            // để cập nhật trạng thái (ví dụ: nếu user vừa hủy đơn)
            _loadOrders();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #${order.orderId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    order.formattedOrderDate,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _fixImageUrl(order.firstProductImageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Iconsax.gallery_slash, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.firstProductNameOrItemCount,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.totalQuantityOfItems} sản phẩm',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),

                        // ✅ THÊM WIDGET HIỂN THỊ SIZE/COLOR VÀO ĐÂY
                        if ((order.firstProductSize != null && order.firstProductSize!.isNotEmpty) || (order.firstProductColor != null && order.firstProductColor!.isNotEmpty))
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Phân loại: ${order.firstProductColor ?? ''}${ (order.firstProductColor != null && order.firstProductSize != null) ? ', ' : '' }${order.firstProductSize ?? ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Trạng thái: ',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                            Text(
                              statusInfo['text'] as String,
                              style: TextStyle(
                                  color: statusInfo['color'] as Color?,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền:',
                    style: TextStyle(color: Colors.grey[800], fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    currencyFormatter.format(order.totalAmount),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // ✅ PHẦN HIỂN THỊ NÚT "MUA LẠI"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hiển thị trạng thái đơn hàng
                  Text('Trạng thái: ${order.status}', style: const TextStyle(color: Colors.grey, fontSize: 13)),

                  // Hiển thị nút nếu đủ điều kiện
                  if (canRepurchase)
                    OutlinedButton(
                      onPressed: () async {
                        final success = await orderProvider.repurchaseOrder(order.orderId);
                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm các sản phẩm từ đơn hàng #${order.orderId} vào giỏ hàng.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(orderProvider.errorMessage ?? 'Mua lại thất bại.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Mua lại'),
                    ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Iconsax.box_1, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text('Chưa có đơn hàng nào', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Tất cả các đơn hàng bạn đã đặt sẽ được hiển thị ở đây.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                context.read<BottomNavProvider>().changeTab(0);
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.refresh),
              label: const Text("Thử lại"),
              onPressed: () => _loadOrders(),
            )
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return {'text': 'Chờ xác nhận', 'color': Colors.orange.shade800};
      case 'CONFIRMED': case 'PROCESSING': return {'text': 'Đang xử lý', 'color': Colors.blue.shade700};
      case 'SHIPPED': return {'text': 'Đang giao', 'color': Colors.teal.shade600};
      case 'DELIVERED': return {'text': 'Đã giao', 'color': Colors.green.shade700};
      case 'COMPLETED': return {'text': 'Hoàn thành', 'color': Colors.green.shade800};
      case 'CANCELLED_BY_USER': case 'CANCELLED_BY_ADMIN': return {'text': 'Đã hủy', 'color': Colors.red.shade700};
      default: return {'text': status, 'color': Colors.grey.shade800};
    }
  }
}