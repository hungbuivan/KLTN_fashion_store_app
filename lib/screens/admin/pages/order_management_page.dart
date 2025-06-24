// file: lib/screens/admin/pages/order_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

// Import các provider và model cần thiết
import '../../../providers/order_provider.dart';
import '../../../models/order_summary_model.dart';
import 'package:fashion_store_app/models/page_response_model.dart';

import 'admin_order_detail_screen.dart';

// Import màn hình chi tiết (sẽ tạo sau)
// import 'admin_order_detail_screen.dart';

// Các hàm helper cục bộ hoặc từ file utils
final currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0, name: '');

String _formatCurrency(double? value) {
  if (value == null) return "N/A";
  return currencyFormatter.format(value) + " VNĐ";
}

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

class AdminOrderManagementPage extends StatefulWidget {
  const AdminOrderManagementPage({super.key});

  @override
  State<AdminOrderManagementPage> createState() => _AdminOrderManagementPageState();
}

class _AdminOrderManagementPageState extends State<AdminOrderManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'createdAt,desc';
  String? _statusFilter;
  int _currentPage = 0;
  final int _pageSize = 15;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  final Map<String, String> _statusMap = {
    'ALL': 'Tất cả trạng thái',
    'PENDING': 'Chờ xác nhận',
    'CONFIRMED': 'Đã xác nhận',
    'PROCESSING': 'Đang xử lý',
    'SHIPPED': 'Đang giao',
    'DELIVERED': 'Đã giao',
    'COMPLETED': 'Hoàn thành',
    'CANCELLED_BY_USER': 'Bị hủy bởi User',
    'CANCELLED_BY_ADMIN': 'Bị hủy bởi Admin',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders(refresh: true);
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
    // Tải thêm khi người dùng cuộn gần đến cuối danh sách
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (provider.adminOrdersPageData?.last == false && !_isLoadingMore) {
        _loadOrders(loadMore: true);
      }
    }
  }

  Future<void> _loadOrders({bool refresh = false, bool loadMore = false}) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    if (refresh) {
      _currentPage = 0;
    } else if (loadMore) {
      _currentPage++;
    }

    if (loadMore && mounted) setState(() { _isLoadingMore = true; });

    await provider.fetchAllOrdersForAdmin(
      page: _currentPage,
      size: _pageSize,
      sort: _currentSort,
      searchTerm: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      status: _statusFilter,
    );

    if (loadMore && mounted) setState(() { _isLoadingMore = false; });
  }

  void _navigateToDetailScreen(int orderId) {
    // TODO: Tạo AdminOrderDetailScreen và điều hướng đến nó
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AdminOrderDetailScreen(orderId: orderId),
    )).then((result) {
      // Tải lại nếu có thay đổi từ màn hình chi tiết
      if (result == true) {
        _loadOrders(refresh: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mở chi tiết đơn hàng ID: $orderId'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(

              title: const Text("Quản lý đơn hàng"),
              centerTitle: true,
              backgroundColor: Colors.blue,

            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Iconsax.filter),
                tooltip: "Lọc theo trạng thái",
                onSelected: (String? value) {
                  if (_statusFilter != value) {
                    setState(() {
                      _statusFilter = (value == 'ALL') ? null : value;
                    });
                    _loadOrders(refresh: true);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return _statusMap.entries.map((entry) {
                    return PopupMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList();
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Iconsax.sort),
                tooltip: "Sắp xếp",
                initialValue: _currentSort,
                onSelected: (String value) {
                  if (_currentSort != value) {
                    setState(() { _currentSort = value; });
                    _loadOrders(refresh: true);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'createdAt,desc', child: Text('Mới nhất')),
                  const PopupMenuItem<String>(value: 'createdAt,asc', child: Text('Cũ nhất')),
                  const PopupMenuItem<String>(value: 'totalPrice,desc', child: Text('Giá trị (Cao > Thấp)')),
                  const PopupMenuItem<String>(value: 'totalPrice,asc', child: Text('Giá trị (Thấp > Cao)')),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã đơn, tên, email...',
                    prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Iconsax.search_status_1),
                      onPressed: () => _loadOrders(refresh: true),
                    ),
                  ),
                  onSubmitted: (_) => _loadOrders(refresh: true),
                ),
              ),
              Expanded(
                child: _buildContent(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(OrderProvider provider) {
    if (provider.isLoading && provider.allAdminOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.allAdminOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton.icon(icon: const Icon(Iconsax.refresh), label: const Text("Thử lại"), onPressed: () => _loadOrders(refresh: true))
            ],
          ),
        ),
      );
    }
    if (provider.allAdminOrders.isEmpty) {
      return RefreshIndicator(
          onRefresh: () => _loadOrders(refresh: true),
          child: Center(
              child: ListView( // Dùng ListView để RefreshIndicator luôn hoạt động
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height / 4),
                  const Center(child: Text('Không có đơn hàng nào khớp.', style: TextStyle(fontSize: 18, color: Colors.grey)))
                ],
              )
          )
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 80),
        itemCount: provider.allAdminOrders.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.allAdminOrders.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
          }
          final order = provider.allAdminOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderSummaryModel order) {
    final statusInfo = _getStatusInfo(order.status);

    // Xử lý null cho orderDate trước khi format
    final String formattedDate = order.orderDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _navigateToDetailScreen(order.orderId),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đơn #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (statusInfo['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(statusInfo['text'] as String, style: TextStyle(color: statusInfo['color'] as Color, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Iconsax.user, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.customerName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.shopping_bag, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(order.firstProductNameOrItemCount, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(order.totalAmount),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return {'text': 'CHỜ XÁC NHẬN', 'color': Colors.orange.shade800};
      case 'CONFIRMED': return {'text': 'ĐÃ XÁC NHẬN', 'color': Colors.blue.shade700};
      case 'PROCESSING': return {'text': 'ĐANG XỬ LÝ', 'color': Colors.blue.shade800};
      case 'SHIPPED': return {'text': 'ĐANG GIAO', 'color': Colors.teal.shade600};
      case 'DELIVERED': return {'text': 'ĐÃ GIAO', 'color': Colors.green.shade700};
      case 'COMPLETED': return {'text': 'HOÀN THÀNH', 'color': Colors.green.shade800};
      case 'CANCELLED_BY_USER': return {'text': 'USER HỦY', 'color': Colors.red.shade700};
      case 'CANCELLED_BY_ADMIN': return {'text': 'ADMIN HỦY', 'color': Colors.red.shade800};
      default: return {'text': status.toUpperCase(), 'color': Colors.grey.shade800};
    }
  }
}