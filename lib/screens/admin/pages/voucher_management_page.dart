// file: lib/screens/admin/pages/voucher_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // Để format ngày tháng

// Import các provider và model cần thiết

import '../../../models/voucher_model.dart';

// Import màn hình thêm/sửa voucher (sẽ tạo ở bước sau)
import '../../../providers/voucher_admin_provider.dart';
import 'add_edit_voucher_screen.dart';


class AdminVoucherManagementPage extends StatefulWidget {
  const AdminVoucherManagementPage({super.key});

  @override
  State<AdminVoucherManagementPage> createState() => _AdminVoucherManagementPageState();
}

class _AdminVoucherManagementPageState extends State<AdminVoucherManagementPage> {
  String _currentSort = 'endDate,desc'; // Mặc định sắp xếp theo ngày hết hạn gần nhất
  int _currentPage = 0;
  final int _pageSize = 15;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVouchers(refresh: true);
    });

    // Thêm listener để xử lý "tải thêm" khi cuộn xuống cuối
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (Provider.of<VoucherAdminProvider>(context, listen: false).pageData?.last == false && !_isLoadingMore) {
          _loadVouchers(loadMore: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers({bool refresh = false, bool loadMore = false}) async {
    final provider = Provider.of<VoucherAdminProvider>(context, listen: false);
    if (refresh) {
      _currentPage = 0;
    } else if (loadMore) {
      _currentPage++;
    } else {
      // Nếu không phải refresh hay loadmore, không làm gì cả
      return;
    }

    if (loadMore && mounted) setState(() { _isLoadingMore = true; });

    await provider.fetchVouchers(
      page: _currentPage,
      size: _pageSize,
      sort: _currentSort,
    );

    if (loadMore && mounted) setState(() { _isLoadingMore = false; });
  }

  void _navigateToAddEditScreen({VoucherModel? voucher}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditVoucherScreen(voucher: voucher),
      ),
    );
    // Nếu kết quả trả về là true (có nghĩa là đã có thay đổi), tải lại danh sách
    if (result == true && mounted) {
      _loadVouchers(refresh: true);
    }
  }

  void _confirmDeleteVoucher(VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa/Vô hiệu hóa'),
        content: Text('Bạn có chắc muốn xóa voucher "${voucher.code}" không? Nếu voucher đã được sử dụng, nó sẽ được chuyển sang trạng thái "Không hoạt động" thay vì bị xóa.'),
        actions: <Widget>[
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Xác nhận', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = context.read<VoucherAdminProvider>();
              final success = await provider.deleteVoucher(voucher.id!);
              if (mounted) {
                // Hiển thị thông báo từ provider (bao gồm cả trường hợp voucher được deactive)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? (success ? 'Xử lý thành công!' : 'Có lỗi xảy ra.')),
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
    return Consumer<VoucherAdminProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Quản lý Mã giảm giá"),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Iconsax.sort),
                tooltip: "Sắp xếp",
                initialValue: _currentSort,
                onSelected: (String value) {
                  if (_currentSort != value) {
                    setState(() { _currentSort = value; });
                    _loadVouchers(refresh: true);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'endDate,desc', child: Text('Hết hạn gần nhất')),
                  const PopupMenuItem<String>(value: 'endDate,asc', child: Text('Hết hạn xa nhất')),
                  const PopupMenuItem<String>(value: 'startDate,desc', child: Text('Mới nhất')),
                  const PopupMenuItem<String>(value: 'id,asc', child: Text('Cũ nhất')),
                  const PopupMenuItem<String>(value: 'discountValue,desc', child: Text('Giá trị giảm cao nhất')),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _loadVouchers(refresh: true),
            child: _buildContent(provider),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddEditScreen(),
            tooltip: 'Tạo Voucher Mới',
            icon: const Icon(Iconsax.add),
            label: const Text("Tạo mới"),
          ),
        );
      },
    );
  }

  Widget _buildContent(VoucherAdminProvider provider) {
    if (provider.isLoading && provider.vouchers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.vouchers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(provider.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton.icon(icon: const Icon(Iconsax.refresh), label: const Text("Thử lại"), onPressed: () => _loadVouchers(refresh: true))
            ],
          ),
        ),
      );
    }
    if (provider.vouchers.isEmpty) {
      return const Center(child: Text('Không có mã giảm giá nào.', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 80), // Padding cho FAB
      itemCount: provider.vouchers.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.vouchers.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)));
        }
        final voucher = provider.vouchers[index];
        return _buildVoucherCard(voucher);
      },
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher) {
    final bool isActive = voucher.isValidNow;
    final theme = Theme.of(context);
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Opacity(
      opacity: isActive ? 1.0 : 0.6,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: isActive ? 2.0 : 0.5,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isActive ? theme.primaryColor.withOpacity(0.5) : Colors.grey.shade300, width: 1)
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.code,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColorDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voucher.discountDisplay, // Sử dụng getter tiện ích từ model
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'ĐANG HOẠT ĐỘNG' : 'KHÔNG H.ĐỘNG',
                      style: TextStyle(
                        color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (voucher.description != null && voucher.description!.isNotEmpty)
                Text(voucher.description!, style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
              const Divider(height: 20),
              _buildInfoRow(Iconsax.calendar_1, 'Hiệu lực:', '${formatter.format(voucher.startDate!)} - ${formatter.format(voucher.endDate!)}'),
              _buildInfoRow(Iconsax.receipt, 'Điều kiện:', voucher.minOrderConditionDisplay),
              _buildInfoRow(Iconsax.ticket_discount, 'Đã dùng:', '${voucher.currentUsageCount} / ${voucher.usageLimitPerVoucher ?? "Không giới hạn"}'),
              _buildInfoRow(Iconsax.user, 'Lượt/Người dùng:', voucher.usageLimitPerUser?.toString() ?? "Không giới hạn"),

              const Divider(height: 20, thickness: 0.5),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Iconsax.edit, size: 18),
                    label: const Text('Sửa'),
                    onPressed: () => _navigateToAddEditScreen(voucher: voucher),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Iconsax.trash, size: 18),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                    onPressed: () => _confirmDeleteVoucher(voucher),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade800)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}