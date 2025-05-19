// file: lib/screens/admin/pages/user_management_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../../models/admin/user_admin_model.dart';
import '../../providers/user_admin_provider.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'id,asc'; // Mặc định sắp xếp
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<UserAdminProvider>(context, listen: false);
      if (provider.users.isEmpty || provider.pageData == null) {
        _loadUsers(refresh: true);
      }
    });
  }

  Future<void> _loadUsers({bool refresh = false, bool loadMore = false}) async {
    final provider = Provider.of<UserAdminProvider>(context, listen: false);
    int pageToLoad = _currentPage;
    if (refresh) {
      pageToLoad = 0;
    } else if (loadMore) {
      if (provider.pageData != null && !provider.pageData!.last) {
        pageToLoad = provider.pageData!.number + 1;
      } else {
        if (mounted) setState(() { _isLoadingMore = false; });
        return;
      }
    }

    if (loadMore && !refresh && !_isLoadingMore) {
      if (mounted) setState(() { _isLoadingMore = true; });
    }

    await provider.fetchUsers(
      page: pageToLoad,
      size: _pageSize,
      sort: _currentSort,
      searchTerm: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );

    if (provider.pageData != null) {
      _currentPage = provider.pageData!.number;
    } else if (refresh) {
      _currentPage = 0;
    }

    if (mounted && loadMore && !refresh) {
      setState(() { _isLoadingMore = false; });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditRoleDialog(UserAdminModel user) {
    String selectedRole = user.role; // Vai trò hiện tại của user
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Thay đổi Vai trò cho "${user.fullName ?? user.email}"'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            items: ['user', 'admin'].map((String role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role.toUpperCase()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                selectedRole = newValue;
              }
            },
            decoration: const InputDecoration(labelText: 'Chọn vai trò mới'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Lưu'),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Đóng dialog trước
                final success = await Provider.of<UserAdminProvider>(context, listen: false)
                    .updateUserRole(user.id.toInt(), selectedRole); // Giả sử id là int
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Cập nhật vai trò thành công!'
                          : Provider.of<UserAdminProvider>(context, listen: false).errorMessage ?? 'Lỗi cập nhật vai trò.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmToggleUserStatus(UserAdminModel user) {
    bool newStatus = !user.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus ? 'Kích hoạt Tài khoản?' : 'Vô hiệu hóa Tài khoản?'),
        content: Text('Bạn có chắc muốn ${newStatus ? "kích hoạt" : "vô hiệu hóa"} tài khoản "${user.fullName ?? user.email}" không?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(newStatus ? 'Kích hoạt' : 'Vô hiệu hóa', style: TextStyle(color: newStatus ? Colors.green : Colors.orange)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<UserAdminProvider>(context, listen: false)
                  .updateUserStatus(user.id.toInt(), newStatus);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Cập nhật trạng thái thành công!'
                        : Provider.of<UserAdminProvider>(context, listen: false).errorMessage ?? 'Lỗi cập nhật trạng thái.'),
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

  void _confirmDeleteUser(UserAdminModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Xóa Người dùng'),
        content: Text('CẢNH BÁO: Bạn có chắc chắn muốn XÓA VĨNH VIỄN người dùng "${user.fullName ?? user.email}" (ID: ${user.id}) không? Hành động này không thể hoàn tác và có thể ảnh hưởng đến dữ liệu liên quan (đơn hàng, đánh giá,...). Thay vào đó, bạn nên cân nhắc việc vô hiệu hóa tài khoản.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('XÓA VĨNH VIỄN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await Provider.of<UserAdminProvider>(context, listen: false)
                  .deleteUser(user.id.toInt());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Đã xóa người dùng "${user.fullName ?? user.email}"'
                        : Provider.of<UserAdminProvider>(context, listen: false).errorMessage ?? 'Lỗi xóa người dùng.'),
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
    return Consumer<UserAdminProvider>(
      builder: (context, provider, child) {
        return Scaffold( // Không cần FAB ở đây nếu không có chức năng "Thêm User" trực tiếp
          body: Column(
            children: [
              // Thanh tìm kiếm và Lọc
              const SizedBox(height: 35,),
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
                        onSubmitted: (_) => _loadUsers(refresh: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.search_status_1),
                      onPressed: () => _loadUsers(refresh: true),
                      tooltip: 'Tìm kiếm',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Iconsax.sort),
                      tooltip: "Sắp xếp",
                      initialValue: _currentSort,
                      onSelected: (String value) {
                        if (_currentSort != value) {
                          setState(() { _currentSort = value; });
                          _loadUsers(refresh: true);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: 'id,asc', child: Text('ID (Tăng dần)')),
                        const PopupMenuItem<String>(value: 'id,desc', child: Text('ID (Giảm dần)')),
                        const PopupMenuItem<String>(value: 'fullName,asc', child: Text('Tên (A-Z)')),
                        const PopupMenuItem<String>(value: 'fullName,desc', child: Text('Tên (Z-A)')),
                        const PopupMenuItem<String>(value: 'email,asc', child: Text('Email (A-Z)')),
                        const PopupMenuItem<String>(value: 'role,asc', child: Text('Vai trò (A-Z)')),
                      ],
                    ),
                  ],
                ),
              ),

              if (provider.isLoading && provider.users.isEmpty && provider.pageData == null)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.errorMessage != null && provider.users.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(provider.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Iconsax.refresh),
                            label: const Text("Thử lại"),
                            onPressed: () => _loadUsers(refresh: true),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              else if (provider.users.isEmpty && !provider.isLoading)
                  const Expanded(child: Center(child: Text('Không có người dùng nào.', style: TextStyle(fontSize: 18, color: Colors.grey))))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadUsers(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: provider.users.length + ((provider.pageData?.last == false || _isLoadingMore) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.users.length) {
                            if (_isLoadingMore) {
                              return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2,)));
                            } else if (provider.pageData?.last == false) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(child: TextButton(onPressed: () => _loadUsers(loadMore: true), child: const Text("Tải thêm..."))),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final user = provider.users[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: Padding( // Thêm Padding cho nội dung ListTile
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: user.isActive ? Colors.green[100] : Colors.red[100],
                                  child: Icon(
                                    user.isActive ? Iconsax.user_tick : Iconsax.user_minus,
                                    color: user.isActive ? Colors.green[700] : Colors.red[700],
                                    size: 24,
                                  ),
                                ),
                                title: Text(user.fullName ?? user.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ID: ${user.id} - Email: ${user.email}', style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                    Text('Vai trò: ${user.role.toUpperCase()} - Trạng thái: ${user.isActive ? "Kích hoạt" : "Vô hiệu hóa"}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                    if(user.phone != null && user.phone!.isNotEmpty) Text('SĐT: ${user.phone}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Iconsax.more, color: Colors.grey),
                                  onSelected: (String value) {
                                    if (value == 'edit_role') {
                                      _showEditRoleDialog(user);
                                    } else if (value == 'toggle_status') {
                                      _confirmToggleUserStatus(user);
                                    } else if (value == 'delete') {
                                      _confirmDeleteUser(user);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'edit_role',
                                      child: ListTile(leading: Icon(Iconsax.user_edit, size: 20), title: Text('Đổi Vai trò')),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'toggle_status',
                                      child: ListTile(leading: Icon(user.isActive ? Iconsax.forbidden_2 : Iconsax.tick_circle, size: 20), title: Text(user.isActive ? 'Vô hiệu hóa' : 'Kích hoạt')),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(leading: Icon(Iconsax.trash, color: Colors.redAccent, size: 20), title: Text('Xóa User', style: TextStyle(color: Colors.redAccent))),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              if (provider.pageData != null && provider.pageData!.totalElements > 0)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trang: ${(provider.pageData!.number) + 1}/${provider.pageData!.totalPages}', style: const TextStyle(fontSize: 12)),
                      Text('Tổng số: ${provider.pageData!.totalElements} người dùng', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )
            ],
          ),
          // Không cần FAB ở đây nếu admin không tạo user trực tiếp
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () { /* TODO: Mở form tạo user mới (nếu có) */ },
          //   child: const Icon(Iconsax.user_add),
          // ),
        );
      },
    );
  }
}
