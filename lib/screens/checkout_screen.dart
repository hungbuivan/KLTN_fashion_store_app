// file: lib/screens/checkout_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Import các provider
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../providers/voucher_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/bottom_nav_provider.dart';

// Import các model và DTO
import '../models/address_models.dart';
import '../models/shipping_address_model.dart';
import '../models/cart_model.dart';

// Import các widget và màn hình con
import '../widgets/applicable_voucher_item.dart';
import 'order_success_screen.dart';
import 'order_history_screen.dart';

// Import các tiện ích
import 'package:fashion_store_app/utils/formatter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // State để lưu trữ địa chỉ giao hàng và phương thức thanh toán
  ShippingAddressModel? _currentShippingAddress;
  String _selectedPaymentMethod = 'COD';
  // ✅ THÊM DÒNG NÀY VÀO
  final TextEditingController _voucherCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreenData();
    });
  }

  // Hàm helper cho InputDecoration của TextFormField và DropdownButtonFormField
  InputDecoration _inputDecoration(String labelText, {IconData? prefixIcon, Widget? suffixIcon, String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText ?? 'Nhập $labelText',
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: Colors.grey[700]) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ✅ THÊM HÀM HELPER NÀY VÀO TRONG CLASS _CheckoutScreenState
  Widget _buildShippingAddressInfo(BuildContext context) {
    // Widget này sẽ hiển thị thông tin từ state `_currentShippingAddress`
    if (_currentShippingAddress == null || _currentShippingAddress!.fullAddressString.trim().isEmpty) {
      return const Text(
        'Vui lòng nhấn "Thay đổi" để thêm địa chỉ giao hàng.',
        style: TextStyle(color: Colors.grey),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentShippingAddress!.fullNameReceiver,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(_currentShippingAddress!.phoneReceiver),
          const SizedBox(height: 4),
          Text(
            _currentShippingAddress!.fullAddressString,
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
        ],
      );
    }
  }

  // ✅ HÀM MỚI: Dán hàm này vào trong _CheckoutScreenState
  void _showApplicableVouchersBottomSheet(BuildContext context, VoucherProvider voucherProvider, double subtotal) {
    // Tải lại danh sách voucher khả dụng mỗi khi mở bottom sheet (để cập nhật)
    voucherProvider.fetchApplicableVouchers(subtotal);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Cho phép sheet cao hơn
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        // Sử dụng Consumer để rebuild khi VoucherProvider thay đổi
        return Consumer<VoucherProvider>(
          builder: (ctx, vp, _) { // vp là VoucherProvider instance
            Widget content;
            if (vp.isLoadingApplicableVouchers) {
              content = const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
            } else if (vp.errorMessage != null && vp.applicableVouchers.isEmpty) {
              content = Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Lỗi tải mã: ${vp.errorMessage}")));
            } else if (vp.applicableVouchers.isEmpty) {
              content = const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("Không có mã giảm giá nào phù hợp cho đơn hàng này.", textAlign: TextAlign.center),
              ));
            } else {
              content = ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: vp.applicableVouchers.length,
                itemBuilder: (BuildContext context, int index) {
                  final voucher = vp.applicableVouchers[index];
                  return ApplicableVoucherItem( // Sử dụng widget bạn đã tạo
                    voucher: voucher,
                    isCurrentlyApplied: voucher.code == vp.appliedVoucherCode,
                    onTap: () async {
                      Navigator.pop(bottomSheetContext); // Đóng bottom sheet
                      _voucherCodeController.text = voucher.code; // Điền mã vào ô input
                      // Tự động gọi hàm áp dụng voucher
                      final success = await context.read<VoucherProvider>().checkAndApplyVoucher(voucher.code, subtotal);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.read<VoucherProvider>().errorMessage ?? (success ? 'Đã áp dụng mã: ${voucher.code}' : 'Không thể áp dụng mã này.')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                        if (success && context.read<VoucherProvider>().checkedVoucherInfo != null) {
                          _voucherCodeController.text = context.read<VoucherProvider>().checkedVoucherInfo!.voucherCode ?? '';
                        }
                      }
                    },
                  );
                },
              );
            }

            // Cho phép cuộn và thay đổi kích thước bottom sheet
            return DraggableScrollableSheet(
                initialChildSize: 0.6, // Chiều cao ban đầu
                minChildSize: 0.3,    // Chiều cao tối thiểu
                maxChildSize: 0.9,    // Chiều cao tối đa
                expand: false,
                builder: (_, scrollController) {
                  return Container(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thanh kéo nhỏ ở trên cùng
                        Center(
                          child: Container(
                            width: 40, height: 5,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        Text("Chọn mã giảm giá", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Expanded(child: SingleChildScrollView(controller: scrollController, child: content)),
                      ],
                    ),
                  );
                });
          },
        );
      },
    );
  }

  String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;

    // Đổi IP nếu không chạy trên emulator
    const String baseUrl = 'http://10.0.2.2:8080'; // Hoặc IP máy thật nếu test trên real device
    return '$baseUrl/${url.startsWith('/') ? url.substring(1) : url}';
  }




  void _initializeScreenData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Khởi tạo địa chỉ mặc định từ thông tin user đã đăng nhập
    if (auth.user != null) {
      List<String> addressParts = auth.user!.address?.split(',').map((e) => e.trim()).toList() ?? [];
      setState(() {
        _currentShippingAddress = ShippingAddressModel(
          fullNameReceiver: auth.user!.fullName ?? '',
          phoneReceiver: auth.user!.phone ?? '',
          street: addressParts.isNotEmpty ? addressParts[0] : '',
          wardName: addressParts.length > 1 ? addressParts[1] : '',
          districtName: addressParts.length > 2 ? addressParts[2] : '',
          provinceName: addressParts.length > 3 ? addressParts[3] : '',
        );
      });
    }



    voucherProvider.removeAppliedVoucher();

    final subtotalForVoucher = cartProvider.cart?.cartTotalPrice ?? 0.0;
    if (subtotalForVoucher > 0) {
      voucherProvider.fetchApplicableVouchers(subtotalForVoucher);
    }
  }

  // Hàm mở BottomSheet để sửa địa chỉ
  void _showEditAddressBottomSheet() async {
    final addressProvider = context.read<AddressProvider>();
    addressProvider.resetAddressSelectionsAndData();
    if (addressProvider.provinces.isEmpty) {
      await addressProvider.fetchProvinces();
    }

    final result = await showModalBottomSheet<ShippingAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: addressProvider,
        child: EditAddressWidget(initialAddress: _currentShippingAddress),
      ),
    );

    if (result != null && mounted) {
      setState(() { _currentShippingAddress = result; });
    }
  }
  void _placeOrder() async {
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    final voucherProvider = context.read<VoucherProvider>();

    // ✅ Kiểm tra đăng nhập
    if (authProvider.isGuest || authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng.')),
      );
      return;
    }

    // ✅ Kiểm tra địa chỉ giao hàng
    if (_currentShippingAddress == null ||
        _currentShippingAddress!.fullAddressString.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng cung cấp địa chỉ giao hàng đầy đủ.')),
      );
      _showEditAddressBottomSheet();
      return;
    }

    // ✅ Kiểm tra giỏ hàng
    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng của bạn đang trống!')),
      );
      return;
    }

    // ✅ Tạo dữ liệu orderRequest
    final cartItemsData = cartProvider.cart!.items.map((item) {
      return CartItemInfoData(
        productId: item.productId,
        quantity: item.quantity,
      );
    }).toList();

    final shippingFee = 30000.0;

    // ✅ Xử lý thanh toán qua VietQR
    if (_selectedPaymentMethod == 'VIETQR') {
      final tempOrder = await orderProvider.createOrder(
        cartItems: cartItemsData,
        shippingAddress: _currentShippingAddress!,
        paymentMethod: _selectedPaymentMethod,
        shippingFee: shippingFee,
        voucherCode: voucherProvider.appliedVoucherCode,
        initialStatus: "AWAITING_PAYMENT",
      );

      if (tempOrder != null && mounted) {

        // ✅ XÓA GIỎ HÀNG VÀ VOUCHER NGAY TRƯỚC KHI HIỂN THỊ DIALOG
        cartProvider.clearCart();
        voucherProvider.removeAppliedVoucher();
        final orderInfo = "TT don hang ${tempOrder.orderId}";
        final paymentInitiated = await paymentProvider.initiateVietQRPayment(
          orderInfo: orderInfo,
          amount: tempOrder.totalAmount ?? 0.0,
        );

        if (paymentInitiated && mounted) {
          _showVietQRDialog();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentProvider.errorMessage ?? 'Không thể tạo mã QR.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Không thể tạo đơn hàng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // ✅ Xử lý thanh toán COD
      final createdOrderDetail = await orderProvider.createOrder(
        cartItems: cartItemsData,
        shippingAddress: _currentShippingAddress!,
        paymentMethod: _selectedPaymentMethod,
        shippingFee: shippingFee,
        voucherCode: voucherProvider.appliedVoucherCode,
        initialStatus: "PENDING",
      );

      if (mounted) {
        if (createdOrderDetail != null) {
          // ✅ XÓA GIỎ HÀNG VÀ VOUCHER NGAY TRƯỚC KHI ĐIỀU HƯỚNG
          cartProvider.clearCart();
          voucherProvider.removeAppliedVoucher();

          Navigator.of(context).pushNamedAndRemoveUntil(
            OrderSuccessScreen.routeName,
                (route) => false,
            arguments: {'orderId': createdOrderDetail.orderId},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.errorMessage ?? 'Đặt hàng thất bại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }



  // Hàm hiển thị Dialog VietQR
  // ✅ THAY THẾ TOÀN BỘ HÀM NÀY
  void _showVietQRDialog() {
    final paymentProvider = context.read<PaymentProvider>();
    final qrInfo = paymentProvider.vietQRResponse;

    if (qrInfo == null || qrInfo.qrData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể lấy thông tin QR.')));
      return;
    }

    String? qrCodeString;
    try {
      // Parse chuỗi JSON bên trong trường qrData
      final Map<String, dynamic> qrDataContent = jsonDecode(qrInfo.qrData!);
      // Lấy ra chuỗi text ngắn để vẽ QR
      qrCodeString = qrDataContent['qrCode'] as String?;
    } catch (e) {
      print("Lỗi parse dữ liệu QR: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dữ liệu QR không hợp lệ.')));
      return;
    }

    // Kiểm tra lại sau khi parse
    if (qrCodeString == null || qrCodeString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy dữ liệu để tạo mã QR.')));
      return;
    }


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Quét mã để thanh toán'),

        content: SizedBox(
          width: double.maxFinite, // Quan trọng: Cho AlertDialog biết chiều rộng tối đa
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sử dụng ứng dụng ngân hàng bất kỳ để quét mã VietQR hoặc sao chép thông tin dưới đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: qrCodeString!, // ✅ Chỉ truyền chuỗi QR ngắn vào đây
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                ),
                const SizedBox(height: 20),
                const Divider(),
                _buildPaymentInfoRow('Ngân hàng:', 'Viettin Bank (970415)'), // Ví dụ
                _buildPaymentInfoRow('Số tài khoản:', qrInfo.accountNo ?? 'N/A'),
                _buildPaymentInfoRow('Tên chủ TK:', qrInfo.accountName ?? 'N/A'),
                _buildPaymentInfoRow('Số tiền:', currencyFormatter.format(qrInfo.amount)),
                _buildPaymentInfoRow('Nội dung:', qrInfo.orderInfo ?? 'N/A', isImportant: true),
                const SizedBox(height: 10),
                const Text(
                  'Lưu ý: Vui lòng nhập ĐÚNG nội dung chuyển khoản.',
                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/order-history', (route) => route.isFirst);
            },
            child: const Text('Tôi đã thanh toán'),
          ),
        ],
      ),
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final voucherProvider = context.watch<VoucherProvider>();
    final orderProvider = context.watch<OrderProvider>(); // Watch OrderProvider cho isLoading của nút đặt hàng

    final cart = cartProvider.cart;
    final _formKey = GlobalKey<FormState>();
    // Hiển thị loading nếu đang tải giỏ hàng lần đầu
    if (cart == null && cartProvider.isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Thanh toán')), body: const Center(child: CircularProgressIndicator()));
    }
    // Hiển thị trạng thái rỗng nếu giỏ hàng không có gì
    if (cart == null || cart.items.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Thanh toán')), body: _buildEmptyStateForCheckout(context));
    }

    // Tính toán các giá trị tổng tiền
    final double subtotal = cart.cartTotalPrice ?? 0.0;
    const double shippingFee = 30000.0;
    final double discountAmount = voucherProvider.currentDiscountAmount;
    final double totalAmount = (subtotal + shippingFee - discountAmount).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận Đơn hàng'),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.grey[100], // Màu nền cho toàn màn hình
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần 1: Thông tin Giao hàng (đã được cấu trúc lại)
              _buildSectionCard(
                title: 'Giao hàng đến',
                trailing: TextButton.icon(
                  icon: const Icon(Iconsax.edit, size: 18),
                  label: const Text('Thay đổi'),
                  onPressed: _showEditAddressBottomSheet,
                ),
                child: _buildShippingAddressInfo(context),
              ),

              // Phần 2: Tóm tắt Đơn hàng
              _buildSectionCard(
                  title: 'Tóm tắt Đơn hàng',
                  child: _buildCartSummary(context, cart)
              ),

              // Phần 3: Mã giảm giá
              _buildSectionCard(
                  title: 'Mã giảm giá',
                  child: _buildVoucherSection(context, voucherProvider, subtotal)
              ),

              // Phần 4: Chi tiết thanh toán
              _buildSectionCard(
                  title: 'Chi tiết thanh toán',
                  child: _buildPriceSummary(context, subtotal, shippingFee, discountAmount, totalAmount)
              ),

              // Phần 5: Phương thức thanh toán
              _buildSectionCard(
                  title: 'Phương thức Thanh toán',
                  child: _buildPaymentMethods(context)
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomPlaceOrderButton(context, orderProvider),
    );
  }

  // --- CÁC WIDGET HELPER ---
  Widget _buildSectionCard({required String title, Widget? trailing, required Widget child}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (trailing != null) trailing,
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
            child,
          ],
        ),
      ),
    );
  }
  Widget _buildCartSummary(BuildContext context, CartModel cart) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cart.items.length,
      itemBuilder: (ctx, i) {
        final cartItem = cart.items[i];

        // Ghép chuỗi để hiển thị Phân loại (Size/Color)
        String variantText = '';
        if (cartItem.color != null && cartItem.color!.isNotEmpty) {
          variantText += 'Màu: ${cartItem.color}';
        }
        if (cartItem.size != null && cartItem.size!.isNotEmpty) {
          if (variantText.isNotEmpty) {
            variantText += ' - ';
          }
          variantText += 'Size: ${cartItem.size}';
        }

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  fixImageUrl(cartItem.productImageUrl),
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(Iconsax.gallery_slash, size: 30, color: Colors.grey),
                ),
              )

          ),
          title: Text(cartItem.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (variantText.isNotEmpty)
                Text(variantText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('SL: ${cartItem.quantity} x ${currencyFormatter.format(cartItem.productPrice)}'),
            ],
          ),
          trailing: Text(currencyFormatter.format(cartItem.itemTotalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
    );
  }




  Widget _buildVoucherSection(BuildContext context, VoucherProvider voucherProvider, double currentSubtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: TextFormField(
                controller: _voucherCodeController, // Giả sử đã có controller này
                decoration: _inputDecoration('Nhập mã giảm giá', prefixIcon: Iconsax.ticket),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value){
                  if(voucherProvider.appliedVoucherCode != null && voucherProvider.appliedVoucherCode != value.trim().toUpperCase()){
                    context.read<VoucherProvider>().removeAppliedVoucher();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
              onPressed: voucherProvider.isLoadingCheckVoucher || _voucherCodeController.text.trim().isEmpty
                  ? null
                  : () async {
                FocusScope.of(context).unfocus();
                final success = await context.read<VoucherProvider>().checkAndApplyVoucher(
                  _voucherCodeController.text.trim(),
                  currentSubtotal,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<VoucherProvider>().errorMessage ?? (success ? 'Áp dụng mã thành công!' : 'Mã không hợp lệ.')), backgroundColor: success ? Colors.green : Colors.red));
                  if (success && context.read<VoucherProvider>().checkedVoucherInfo != null) {
                    _voucherCodeController.text = context.read<VoucherProvider>().checkedVoucherInfo!.voucherCode ?? '';
                  }
                }
              },
              child: voucherProvider.isLoadingCheckVoucher
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Áp dụng'),
            ),
          ],
        ),
        if (voucherProvider.appliedVoucherCode != null)
          Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Đã áp dụng: ${voucherProvider.appliedVoucherCode}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Iconsax.trash, color: Colors.grey, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Xóa mã đã áp dụng', onPressed: (){
                        context.read<VoucherProvider>().removeAppliedVoucher();
                        _voucherCodeController.clear();
                      })
                    ],
                  ),
                  if(voucherProvider.checkedVoucherInfo?.description != null && voucherProvider.checkedVoucherInfo!.description!.isNotEmpty)
                    Text(voucherProvider.checkedVoucherInfo!.description!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              )
          ),
        TextButton(
            onPressed: voucherProvider.isLoadingApplicableVouchers ? null : () => _showApplicableVouchersBottomSheet(context, voucherProvider, currentSubtotal), // Giả sử có hàm này
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Xem các mã giảm giá", style: TextStyle(decoration: TextDecoration.underline, color: Theme.of(context).colorScheme.primary)),
                if(voucherProvider.isLoadingApplicableVouchers) const SizedBox(width: 8),
                if(voucherProvider.isLoadingApplicableVouchers) const SizedBox(width:12, height:12, child: CircularProgressIndicator(strokeWidth: 2))
              ],
            )
        ),
      ],
    );
  }

  Widget _buildPriceSummary(BuildContext context, double subtotal, double shippingFee, double discountAmount, double totalAmount) {
    return Column(
      children: [
        _buildPriceDetailRow('Tổng tiền hàng:', currencyFormatter.format(subtotal)),
        _buildPriceDetailRow('Phí vận chuyển:', currencyFormatter.format(shippingFee)),
        if (discountAmount > 0)
          _buildPriceDetailRow(
              'Giảm giá voucher:',
              '-${currencyFormatter.format(discountAmount)}',
              color: Colors.green.shade700
          ),
        const Divider(thickness: 0.5, height: 20),
        _buildPriceDetailRow('Tổng cộng:', currencyFormatter.format(totalAmount), isTotal: true),
      ],
    );
  }

  Widget _buildPriceDetailRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(
                  label,
                  style: TextStyle(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                      color: Colors.black87
                  )
              )
          ),
          const SizedBox(width: 10),
          Flexible(
              child: Text(
                value,
                style: TextStyle(
                    fontSize: isTotal ? 18 : 15,
                    fontWeight: FontWeight.bold,
                    color: color ?? (isTotal ? Theme.of(context).colorScheme.error : Colors.black87)
                ),
                textAlign: TextAlign.end,
              )
          ),
        ],
      ),
    );
  }


  // ✅ CẬP NHẬT: Thêm lựa chọn VietQR
  Widget _buildPaymentMethods(BuildContext context) {
    final paymentMethods = [
      {'code': 'COD', 'name': 'Thanh toán khi nhận hàng (COD)', 'icon': Iconsax.money_send},
      {'code': 'VIETQR', 'name': 'Chuyển khoản bằng mã VietQR', 'icon': Iconsax.scan_barcode},
    ];

    return Column(
      children: paymentMethods.map((method) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: RadioListTile<String>(
            title: Text(method['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
            value: method['code'] as String,
            groupValue: _selectedPaymentMethod,
            onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
            secondary: Icon(method['icon'] as IconData?, color: Theme.of(context).colorScheme.primary),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }).toList(),
    );
  }
  Widget _buildBottomPlaceOrderButton(BuildContext context, OrderProvider orderProvider) {
    // Lấy các provider cần thiết để tính toán và kiểm tra trạng thái loading
    final cartProvider = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final voucherProvider = context.watch<VoucherProvider>();

    final cart = cartProvider.cart;
    if (cart == null || cart.items.isEmpty) return const SizedBox.shrink(); // Không hiển thị gì nếu giỏ hàng trống

    // Tính toán lại tổng tiền để hiển thị
    final double totalAmount = (cart.cartTotalPrice! + 30000.0 - voucherProvider.currentDiscountAmount).clamp(0, double.infinity);

    // Kiểm tra xem có bất kỳ provider nào đang trong trạng thái loading không
    bool isAnyLoading = orderProvider.isLoading ||
        cartProvider.isLoading ||
        addressProvider.isLoadingProvinces ||
        addressProvider.isLoadingDistricts ||
        addressProvider.isLoadingWards ||
        voucherProvider.isLoadingCheckVoucher;

    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).padding.bottom > 0 ? 8.0 : 16.0).copyWith(
          left: 16.0, right: 16.0, top: 12.0,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 8.0 : 16.0
      ),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [ BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 0, blurRadius: 10, offset: const Offset(0,-3)) ],
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tổng thanh toán:", style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(
                  currencyFormatter.format(totalAmount), // Sử dụng currencyFormatter đã định nghĩa
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
              ),
            ],
          ),
          ElevatedButton(
              onPressed: isAnyLoading ? null : _placeOrder, // Disable nút khi đang loading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isAnyLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Đặt hàng ngay')
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateForCheckout(BuildContext context){
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Iconsax.shopping_cart, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Giỏ hàng trống để thanh toán',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'Vui lòng thêm sản phẩm vào giỏ trước khi thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Cập nhật tab hiện tại về Trang chủ (tab index 0)
                context.read<BottomNavProvider>().changeTab(0);

                // Xoá hết các màn hình trước đó và quay về NavigationMenu
                Navigator.of(context).pushNamedAndRemoveUntil('/navigation', (route) => false);
              },


              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              ),
              child: const Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoRow(String label, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isImportant ? Colors.red : null
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã sao chép: $value'), duration: const Duration(seconds: 1))
                );
              }
            },
            child: const Icon(Iconsax.copy, size: 16, color: Colors.blue),
          )
        ],
      ),
    );
  }

}

// ✅ WIDGET MỚI: Form để sửa/thêm địa chỉ trong BottomSheet
// WIDGET HIỂN THỊ FORM SỬA/THÊM ĐỊA CHỈ TRONG BOTTOMSHEET
class EditAddressWidget extends StatefulWidget {
  final ShippingAddressModel? initialAddress;

  const EditAddressWidget({super.key, this.initialAddress});

  @override
  State<EditAddressWidget> createState() => _EditAddressWidgetState();
}
class _EditAddressWidgetState extends State<EditAddressWidget> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();

  // State cục bộ để quản lý lựa chọn dropdown, giúp UI phản hồi nhanh hơn
  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;

  late AddressProvider _addressProviderListener;

  @override
  void initState() {
    super.initState();
    // Lắng nghe thay đổi từ AddressProvider để cập nhật UI
    _addressProviderListener = Provider.of<AddressProvider>(context, listen: false);
    _addressProviderListener.addListener(_onAddressProviderChange);

    // Điền dữ liệu ban đầu vào form nếu có
    if (widget.initialAddress != null) {
      _nameController.text = widget.initialAddress!.fullNameReceiver;
      _phoneController.text = widget.initialAddress!.phoneReceiver;
      _streetController.text = widget.initialAddress!.street;

      // TODO: Logic để tự động chọn lại Tỉnh/Huyện/Xã từ initialAddress
      // Việc này cần sự phối hợp giữa các lần gọi API và setState, sẽ phức tạp hơn.
      // Hiện tại, người dùng sẽ cần chọn lại từ đầu.
    }
  }

  @override
  void dispose() {
    _addressProviderListener.removeListener(_onAddressProviderChange);
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // Cập nhật state cục bộ khi có thay đổi từ provider
  void _onAddressProviderChange() {
    if (mounted) {
      final addressProvider = context.read<AddressProvider>();
      setState(() {
        _selectedProvince = addressProvider.selectedProvince;
        _selectedDistrict = addressProvider.selectedDistrict;
        _selectedWard = addressProvider.selectedWard;
      });
    }
  }

  // Hàm lưu địa chỉ và đóng BottomSheet
  void _saveAddress() {
    // ✅ Biến _formKey giờ đây đã được định nghĩa và có thể sử dụng
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Tạo đối tượng ShippingAddressModel mới từ dữ liệu form
    final newAddress = ShippingAddressModel(
      fullNameReceiver: _nameController.text.trim(),
      phoneReceiver: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      wardName: _selectedWard?.name ?? '',
      districtName: _selectedDistrict?.name ?? '',
      provinceName: _selectedProvince?.name ?? '',
    );
    // Trả về địa chỉ mới cho màn hình CheckoutScreen
    Navigator.of(context).pop(newAddress);
  }

  // Hàm helper cho InputDecoration
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dùng context.watch để UI của dropdown có thể rebuild khi provider thay đổi
    final addressProvider = context.watch<AddressProvider>();

    // Bọc trong một Container để có nền và bo góc
    return Container(
        // Padding để tránh bị bàn phím che mất
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
    decoration: BoxDecoration(
    color: Theme.of(context).canvasColor,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    // Bọc nội dung trong một DraggableScrollableSheet để có thể cuộn và thay đổi kích thước
    child: DraggableScrollableSheet(
    initialChildSize: 0.9, // Chiều cao ban đầu
    maxChildSize: 0.9,
    expand: false,
    builder: (_, scrollController) {
    return Column(
    children: [
    // Thanh kéo
    Center(
    child: Container(
    width: 40, height: 5,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
    ),
    ),
    Text('Cập nhật Địa chỉ Giao hàng', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    Expanded(
    child: SingleChildScrollView(
    controller: scrollController,
    child: Form(
    key: _formKey,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    TextFormField(controller: _nameController, decoration: _inputDecoration('Tên người nhận *'), validator: (v)=>v==null||v.isEmpty?'Không được bỏ trống':null),
    const SizedBox(height: 12),
    TextFormField(controller: _phoneController, decoration: _inputDecoration('Số điện thoại *'), keyboardType: TextInputType.phone, validator: (v)=>v==null||v.isEmpty?'Không được bỏ trống':null),
    const SizedBox(height: 16),

    // Dropdown Tỉnh/Thành phố
    DropdownButtonFormField<Province>(
    value: _selectedProvince, isExpanded: true,
    decoration: _inputDecoration("Tỉnh/Thành phố *"),
    hint: addressProvider.isLoadingProvinces ? const Text("Đang tải...") : const Text("Chọn Tỉnh/Thành"),
    items: addressProvider.provinces.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: addressProvider.isLoadingProvinces ? null : (p) => context.read<AddressProvider>().setSelectedProvince(p),
    validator: (v) => v == null ? 'Vui lòng chọn' : null,
    ),
    const SizedBox(height: 12),

    // Dropdown Quận/Huyện
    DropdownButtonFormField<District>(
    value: _selectedDistrict, isExpanded: true,
    decoration: _inputDecoration("Quận/Huyện *"),
    hint: addressProvider.isLoadingDistricts ? const Text("Đang tải...") : const Text("Chọn Quận/Huyện"),
    disabledHint: _selectedProvince == null ? const Text("Chọn Tỉnh/Thành trước") : null,
    items: addressProvider.districts.map((d) => DropdownMenuItem(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: _selectedProvince == null ? null : (d) => context.read<AddressProvider>().setSelectedDistrict(d),
    validator: (v) => v == null ? 'Vui lòng chọn' : null,
    ),
    const SizedBox(height: 12),

    // Dropdown Phường/Xã
    DropdownButtonFormField<Ward>(
    value: _selectedWard, isExpanded: true,
    decoration: _inputDecoration("Phường/Xã *"),
    hint: addressProvider.isLoadingWards ? const Text("Đang tải...") : const Text("Chọn Phường/Xã"),
    disabledHint: _selectedDistrict == null ? const Text("Chọn Quận/Huyện trước") : null,
    items: addressProvider.wards.map((w) => DropdownMenuItem(value: w, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: _selectedDistrict == null ? null : (w) => context.read<AddressProvider>().setSelectedWard(w),
    validator: (v) => v == null ? 'Vui lòng chọn' : null,
    ),
    const SizedBox(height: 12),

    TextFormField(controller: _streetController, decoration: _inputDecoration('Số nhà, tên đường *'), validator: (v)=>v==null||v.isEmpty?'Không được bỏ trống':null),
    ],
    ),
    ),
    ),
    ),
    const SizedBox(height: 16),
    SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
    icon: const Icon(Iconsax.location_tick),
    onPressed: _saveAddress,
    label: const Text('Lưu và sử dụng địa chỉ này'),
    style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
         ),
        ),
       )
        ],

    );
    },
    )
    );
  }



}



