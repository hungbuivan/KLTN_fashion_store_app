// file: lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fashion_store_app/utils/formatter.dart';
// Import các provider và model cần thiết
import '../providers/order_provider.dart';
import '../models/order_detail_model.dart';
import '../models/order_item_model.dart';


// Import màn hình đánh giá sản phẩm (sẽ tạo sau)
// import 'product_review_screen.dart';

// Các hàm helper (bạn có thể đưa chúng vào file utils chung)


String _fixImageUrl(String? originalUrlFromApi) {
  const String serverBase = "http://10.0.2.2:8080";
  if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
    return 'https://via.placeholder.com/150?Text=No+Image';
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

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});
  static const routeName = '/order-detail';

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
   Future<void>? _fetchOrderDetailFuture;

   @override
   void initState() {
     super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
       setState(() {
         _fetchOrderDetailFuture = _loadOrderDetail();
       });
     });
   }




   Future<void> _loadOrderDetail() {
    return Provider.of<OrderProvider>(context, listen: false)
        .fetchOrderDetailForUser(widget.orderId);
  }

  // Hàm hiển thị dialog xác nhận hủy đơn
  void _confirmCancelOrder(BuildContext context, OrderDetailModel order) {
    // TODO: Thêm TextEditingController nếu bạn muốn user nhập lý do hủy
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Hủy Đơn'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: <Widget>[
          TextButton(child: const Text('Không'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Hủy Đơn', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Đóng dialog trước
              final orderProvider = context.read<OrderProvider>();
              final success = await orderProvider.cancelOrderByUser(order.orderId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Yêu cầu hủy đơn hàng đã được gửi.' : (orderProvider.errorMessage ?? 'Hủy đơn thất bại.')),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                if (success) {
                  // Quay lại màn hình lịch sử đơn hàng
                  Navigator.of(context).pushNamed('/order-history');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // Hàm xử lý khi nhấn "Đã nhận được hàng"
  void _handleConfirmDelivery(BuildContext context, OrderDetailModel order) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.confirmDeliveryByUser(order.orderId);
    if (mounted) {
      if(success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã xác nhận!'), backgroundColor: Colors.green),
        );
        // TODO: Điều hướng đến màn hình đánh giá sản phẩm
        // Navigator.of(context).pushReplacement(MaterialPageRoute(
        //   builder: (ctx) => ProductReviewScreen(order: orderProvider.currentOrderDetail!),
        // ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TODO: Chuyển sang màn hình đánh giá sản phẩm.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderProvider.errorMessage ?? 'Lỗi xác nhận.'), backgroundColor: Colors.red),
        );
      }
    }
  }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text('Chi tiết Đơn hàng #${widget.orderId}'),
         elevation: 1,
       ),
       body: _fetchOrderDetailFuture == null
           ? const Center(child: CircularProgressIndicator())
           : FutureBuilder(
         future: _fetchOrderDetailFuture,
         builder: (ctx, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
           } else {
             return Consumer<OrderProvider>(
               builder: (ctx, orderProvider, child) {
                 if (orderProvider.isLoading &&
                     orderProvider.currentOrderDetail == null) {
                   return const Center(child: CircularProgressIndicator());
                 }

                 if (orderProvider.errorMessage != null &&
                     orderProvider.currentOrderDetail == null) {
                   return Center(
                       child: Text(orderProvider.errorMessage!));
                 }

                 final order = orderProvider.currentOrderDetail;
                 if (order == null) {
                   return const Center(
                       child: Text('Không tìm thấy thông tin đơn hàng.'));
                 }

                 return _buildOrderDetailContent(
                     context, order, orderProvider.isUpdatingStatus);
               },
             );
           }
         },
       ),
     );
   }



   Widget _buildOrderDetailContent(BuildContext context, OrderDetailModel order, bool isUpdatingStatus) {
    final statusInfo = _getStatusInfo(order.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần 1: Thông tin chung
          _buildSectionCard(
            title: 'Thông tin Đơn hàng',
            child: Column(
              children: [
                _buildInfoRow('Mã đơn hàng:', '#${order.orderId}'),
                _buildInfoRow('Ngày đặt hàng:', order.formattedOrderDate),
                _buildInfoRow('Trạng thái:', statusInfo['text'] as String, valueColor: statusInfo['color'] as Color?),
                _buildInfoRow('Phương thức thanh toán:', order.paymentMethod),
              ],
            ),
          ),

          // Phần 2: Địa chỉ giao hàng
          _buildSectionCard(
            title: 'Địa chỉ Giao hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.shippingAddress?.fullNameReceiver ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(order.shippingAddress?.phoneReceiver ?? 'N/A'),
                Text(order.shippingAddress?.fullAddressString ?? 'N/A'),
              ],
            ),
          ),

          // Phần 3: Danh sách sản phẩm
          _buildSectionCard(
            title: 'Danh sách Sản phẩm (${order.items.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (ctx, i) => _buildOrderItemTile(order.items[i], order),
              separatorBuilder: (ctx, i) => const Divider(height: 15),
            ),
          ),

          // Phần 4: Chi tiết thanh toán
          _buildSectionCard(
            title: 'Chi tiết Thanh toán',
            child: Column(
              children: [
                _buildPriceDetailRow('Tổng tiền hàng:', currencyFormatter.format(order.subtotalAmount)),
                _buildPriceDetailRow('Phí vận chuyển:', currencyFormatter.format(order.shippingFee)),
                if (order.voucherDiscountAmount != null && order.voucherDiscountAmount! > 0)
                  _buildPriceDetailRow(
                      'Giảm giá (${order.appliedVoucherCode ?? ''}):',
                      '-${currencyFormatter.format(order.voucherDiscountAmount)}',
                      color: Colors.green.shade700
                  ),
                const Divider(thickness: 1, height: 20),
                _buildPriceDetailRow('Tổng cộng:', currencyFormatter.format(order.totalAmount), isTotal: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Phần 5: Các nút hành động
          if (isUpdatingStatus)
            const Center(child: CircularProgressIndicator())
          else
            _buildActionButtons(context, order),
        ],
      ),
    );
  }

  // Widget cho mỗi sản phẩm trong đơn hàng
   Widget _buildOrderItemTile(OrderItemModel item, OrderDetailModel order) {
     final bool canReview = order.status.toUpperCase() == 'DELIVERED' || order.status.toUpperCase() == 'COMPLETED';
     print("👉 Màu: ${item.color}, Size: ${item.size}");

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             SizedBox(
               width: 60,
               height: 60,
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(8),
                 child: Image.network(
                   _fixImageUrl(item.productImageUrl),
                   fit: BoxFit.cover,
                   errorBuilder: (c, e, s) => const Icon(Iconsax.gallery_slash),
                 ),
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                   if (item.size != null && item.size!.isNotEmpty) Text('Size: ${item.size}'),
                   if (item.color != null && item.color!.isNotEmpty) Text('Màu: ${item.color}'),
                   Text('SL: ${item.quantity}'),
                 ],
               ),
             ),
             const SizedBox(width: 12),
             Text(currencyFormatter.format(item.priceAtPurchase), style: const TextStyle(fontWeight: FontWeight.w500)),
           ],
         ),

         // Nút đánh giá
         if (canReview)
           Align(
             alignment: Alignment.centerRight,
             child: OutlinedButton(
               onPressed: () {
                 Navigator.of(context).pushNamed(
                   '/add-review', // hoặc AddReviewScreen.routeName nếu bạn dùng const
                   arguments: {
                     'orderId': order.orderId,
                     'productToReview': item,
                   },
                 );
               },
               child: const Text('Viết đánh giá'),
             ),
           ),
       ],
     );
   }

   // Widget cho các nút hành động của người dùng
  Widget _buildActionButtons(BuildContext context, OrderDetailModel order) {
    // Nút "Hủy đơn hàng"
    bool canCancel = order.status.toUpperCase() == 'PENDING' || order.status.toUpperCase() == 'CONFIRMED';
    bool canReview = order.status.toUpperCase() == 'DELIVERED' || order.status.toUpperCase() == 'COMPLETED';

    // Nút "Đã nhận được hàng"
    bool canConfirmDelivery = order.status.toUpperCase() == 'SHIPPED';

    if (!canCancel && !canConfirmDelivery) {
      return const SizedBox.shrink(); // Không hiển thị gì nếu không có hành động nào
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCancel)
          OutlinedButton(
            onPressed: () => _confirmCancelOrder(context, order),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Hủy đơn hàng'),
          ),
        if (canCancel) const SizedBox(height: 10),

        if (canConfirmDelivery)
          ElevatedButton(
            onPressed: () => _handleConfirmDelivery(context, order),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Đã nhận được hàng'),
          ),
      ],
    );
  }
// Widget helper để tạo các section card
  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Divider(height: 20, thickness: 0.5),
            child,
          ],
        ),
      ),
    );
  }

  // Widget helper để hiển thị một dòng thông tin
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper để hiển thị một dòng trong chi tiết thanh toán
  Widget _buildPriceDetailRow(String label, String value, {bool isTotal = false, Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 15, fontWeight: FontWeight.bold, color: color ?? (isTotal ? theme.colorScheme.primary : Colors.black87))),
        ],
      ),
    );
  }

  // Helper để lấy màu sắc và text cho trạng thái đơn hàng
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return {'text': 'Chờ xác nhận', 'color': Colors.orange.shade800};
      case 'CONFIRMED':
      case 'PROCESSING':
        return {'text': 'Đang xử lý', 'color': Colors.blue.shade700};
      case 'SHIPPED':
        return {'text': 'Đang giao', 'color': Colors.teal.shade600};
      case 'DELIVERED':
        return {'text': 'Đã giao', 'color': Colors.green.shade700};
      case 'COMPLETED':
        return {'text': 'Hoàn thành', 'color': Colors.green.shade800};
      case 'CANCELLED_BY_USER':
      case 'CANCELLED_BY_ADMIN':
        return {'text': 'Đã hủy', 'color': Colors.red.shade700};
      default:
        return {'text': status, 'color': Colors.grey.shade800};
    }
  }
}