// file: lib/screens/admin/pages/admin_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// Import các provider và model cần thiết
import '../../../providers/order_provider.dart';
import '../../../models/order_detail_model.dart';
import '../../../models/order_item_model.dart';
// import '../../../screens/product_detail_screen.dart'; // Để điều hướng khi nhấn vào sản phẩm

// Các hàm helper cục bộ hoặc từ file utils
final currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0, name: '');
String _formatCurrency(double? value) { if (value == null) return "N/A"; return currencyFormatter.format(value) + " VNĐ"; }
String _fixImageUrl(String? url) { const String serverBase = "http://10.0.2.2:8080"; if (url == null || url.isEmpty) return 'https://via.placeholder.com/150'; if (url.startsWith('http')) { if (url.contains('://localhost:8080')) return url.replaceFirst('://localhost:8080', serverBase); return url; } if (url.startsWith('/')) return serverBase + url; return '$serverBase/images/products/$url';}


class AdminOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});
  static const routeName = '/admin-order-detail';

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late Future<void> _fetchOrderDetailFuture;

  String? _selectedNextStatus;
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrderDetailFuture = _loadOrderDetail();
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetail() {
    return Provider.of<OrderProvider>(context, listen: false)
        .fetchOrderDetailForAdmin(widget.orderId);
  }

  void _handleUpdateStatus(BuildContext context, OrderDetailModel order) {
    if (_selectedNextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn trạng thái mới.'), backgroundColor: Colors.orangeAccent));
      return;
    }
    if (_selectedNextStatus == 'CANCELLED_BY_ADMIN' && _cancelReasonController.text.trim().isEmpty) {
      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Thiếu thông tin'), content: const Text('Vui lòng nhập lý do hủy đơn hàng.'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
      return;
    }
    final provider = context.read<OrderProvider>();
    provider.updateAdminOrderStatus(
      order.orderId,
      _selectedNextStatus!,
      reason: _cancelReasonController.text.trim(),
    ).then((success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Cập nhật trạng thái thành công!' : (provider.errorMessage ?? 'Cập nhật thất bại.')), backgroundColor: success ? Colors.green : Colors.red));
        if (success) {
          // Reset lựa chọn trạng thái sau khi cập nhật thành công
          setState(() {
            _selectedNextStatus = null;
            _cancelReasonController.clear();
          });
        }
      }
    });
  }

  // ✅ THÊM HÀM HELPER NÀY VÀO
  InputDecoration _inputDecoration(String label, {String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: Colors.grey[700]) : null,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Đơn hàng #${widget.orderId.toString().padLeft(6, '0')}'),
        elevation: 1,

        backgroundColor: Colors.blue,

      ),
      body: FutureBuilder(
        future: _fetchOrderDetailFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Consumer<OrderProvider>(
              builder: (ctx, orderProvider, child) {
                final order = orderProvider.currentOrderDetail;
                if (orderProvider.isLoading && order == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (orderProvider.errorMessage != null && order == null) {
                  return Center(child: Text(orderProvider.errorMessage!));
                }
                if (order == null) {
                  return const Center(child: Text('Không tìm thấy thông tin đơn hàng.'));
                }
                return _buildAdminOrderDetailContent(context, order, orderProvider.isUpdatingStatus);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildAdminOrderDetailContent(BuildContext context, OrderDetailModel order, bool isUpdatingStatus) {
    final statusInfo = _getStatusInfo(order.status);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(title: 'Thông tin Khách hàng', child: Column(children: [_buildInfoRow('Tên khách hàng:', order.userName ?? 'N/A'), _buildInfoRow('Email:', order.userEmail ?? 'N/A'), _buildInfoRow('Số điện thoại:', order.userPhone ?? 'N/A')])),
          _buildSectionCard(title: 'Thông tin Đơn hàng', child: Column(children: [_buildInfoRow('Mã đơn hàng:', '#${order.orderId}'), _buildInfoRow('Ngày đặt hàng:', order.formattedOrderDate), _buildInfoRow('Trạng thái:', statusInfo['text'] as String, valueColor: statusInfo['color'] as Color?), _buildInfoRow('Phương thức thanh toán:', order.paymentMethod)])),
          _buildSectionCard(title: 'Địa chỉ Giao hàng', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.shippingAddress?.fullNameReceiver ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)), Text(order.shippingAddress?.phoneReceiver ?? 'N/A'), Text(order.shippingAddress?.fullAddressString ?? 'N/A', style: const TextStyle(height: 1.4))])),
          _buildSectionCard(title: 'Danh sách Sản phẩm (${order.items.length})', child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: order.items.length, itemBuilder: (ctx, i) => _buildOrderItemTile(order.items[i]), separatorBuilder: (ctx, i) => const Divider(height: 15))),
          _buildSectionCard(title: 'Chi tiết Thanh toán', child: Column(children: [_buildPriceDetailRow('Tổng tiền hàng:', _formatCurrency(order.subtotalAmount)), _buildPriceDetailRow('Phí vận chuyển:', _formatCurrency(order.shippingFee)), if (order.voucherDiscountAmount != null && order.voucherDiscountAmount! > 0) _buildPriceDetailRow('Giảm giá (${order.appliedVoucherCode ?? ''}):', '-${_formatCurrency(order.voucherDiscountAmount)}', color: Colors.green.shade700), const Divider(thickness: 1, height: 20), _buildPriceDetailRow('Tổng cộng:', _formatCurrency(order.totalAmount), isTotal: true)])),
          _buildSectionCard(title: 'Hành động', child: isUpdatingStatus ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())) : _buildAdminActions(context, order)),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context, OrderDetailModel order) {
    final List<String> possibleNextStatuses = _getPossibleNextStatuses(order.status);
    if (possibleNextStatuses.isEmpty) {
      return const Text("Đơn hàng đã ở trạng thái cuối cùng.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedNextStatus,
          decoration: _inputDecoration("Chọn trạng thái mới *"),
          hint: const Text("Chọn hành động..."),
          items: possibleNextStatuses.map((status) => DropdownMenuItem<String>(value: status, child: Text(_getStatusInfo(status)['text'] as String))).toList(),
          onChanged: (value) => setState(() => _selectedNextStatus = value),
          validator: (value) => value == null ? 'Vui lòng chọn một hành động' : null,
        ),
        if (_selectedNextStatus == 'CANCELLED_BY_ADMIN')
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextFormField(
              controller: _cancelReasonController,
              decoration: _inputDecoration("Lý do hủy *", hint: "Ví dụ: Hết hàng..."),
              maxLines: 2,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập lý do hủy' : null,
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Iconsax.save_2),
          label: const Text('Lưu thay đổi'),
          onPressed: () => _handleUpdateStatus(context, order),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
        )
      ],
    );
  }

  List<String> _getPossibleNextStatuses(String currentStatus) {
    switch (currentStatus.toUpperCase()) {
      case 'PENDING': return ['CONFIRMED', 'CANCELLED_BY_ADMIN'];
      case 'CONFIRMED': return ['PROCESSING', 'CANCELLED_BY_ADMIN'];
      case 'PROCESSING': return ['SHIPPED', 'CANCELLED_BY_ADMIN'];
      case 'SHIPPED': return ['DELIVERED', 'CANCELLED_BY_ADMIN'];
      case 'DELIVERED': return ['COMPLETED'];
      default: return [];
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {return Card(margin: const EdgeInsets.only(bottom: 16), elevation: 0.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)), const Divider(height: 20, thickness: 0.5), child]))); }
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey[700])), Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis))])); }
  Widget _buildPriceDetailRow(String label, String value, {bool isTotal = false, Color? color}) {final theme = Theme.of(context); return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal, color: Colors.black87)), Text(value, style: TextStyle(fontSize: isTotal ? 18 : 15, fontWeight: FontWeight.bold, color: color ?? (isTotal ? theme.colorScheme.primary : Colors.black87)))])); }
  Widget _buildOrderItemTile(OrderItemModel item) {
    print('Color: ${item.color}, Size: ${item.size}');

    return InkWell(
      onTap: () {
        // TODO: Navigate to ProductDetailScreen(productId: item.productId!)
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hình ảnh sản phẩm
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

          // Thông tin sản phẩm
          Expanded(

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên sản phẩm
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
                // Số lượng
                Text(
                  'SL: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Giá sản phẩm
          Text(
            _formatCurrency(item.priceAtPurchase),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) { switch (status.toUpperCase()) { case 'PENDING': return {'text': 'Chờ xác nhận', 'color': Colors.orange.shade800}; case 'CONFIRMED': return {'text': 'Đã xác nhận', 'color': Colors.blue.shade700}; case 'PROCESSING': return {'text': 'Đang xử lý', 'color': Colors.blue.shade800}; case 'SHIPPED': return {'text': 'Đang giao', 'color': Colors.teal.shade600}; case 'DELIVERED': return {'text': 'Đã giao', 'color': Colors.green.shade700}; case 'COMPLETED': return {'text': 'Hoàn thành', 'color': Colors.green.shade800}; case 'CANCELLED_BY_USER': return {'text': 'User Hủy', 'color': Colors.red.shade700}; case 'CANCELLED_BY_ADMIN': return {'text': 'Admin Hủy', 'color': Colors.red.shade800}; default: return {'text': status.toUpperCase(), 'color': Colors.grey.shade800}; } }
}