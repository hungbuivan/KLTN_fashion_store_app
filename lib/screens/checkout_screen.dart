// file: lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Import các provider cần thiết
import '../providers/cart_provider.dart';
import '../providers/address_provider.dart';
import '../providers/voucher_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart'; // Quan trọng
import '../providers/bottom_nav_provider.dart';
import 'package:fashion_store_app/utils/formatter.dart';
import 'package:fashion_store_app/utils/fiximageurl.dart';

// Import các model
import '../models/address_models.dart';
import '../models/shipping_address_model.dart';
// import '../models/cart_item_model.dart'; // CartProvider đã có CartModel chứa CartItemModel

// Import formatter
import '../utils/formatter.dart';
import '../widgets/applicable_voucher_item.dart'; // Đảm bảo đường dẫn này đúng

// Import màn hình thành công (nếu có)
// import 'order_success_screen.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  static const routeName = '/checkout'; // Tên route để điều hướng

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường người dùng nhập
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _streetAddressController = TextEditingController();
  final TextEditingController _voucherCodeController = TextEditingController();

  // State cục bộ cho các dropdown địa chỉ để DropdownButtonFormField có thể hiển thị giá trị đã chọn
  Province? _currentSelectedProvince;
  District? _currentSelectedDistrict;
  Ward? _currentSelectedWard;

  String _selectedPaymentMethod = 'COD'; // Phương thức thanh toán mặc định

  late AddressProvider _addressProviderListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreenData(); // Gọi hàm khởi tạo dữ liệu
      // Lắng nghe thay đổi từ AddressProvider để cập nhật UI dropdown
      _addressProviderListener = Provider.of<AddressProvider>(context, listen: false);
      _addressProviderListener.addListener(_onAddressProviderChange);
    });
  }

  // Trong class _CheckoutScreenState
  String _fixImageUrl(String? originalUrlFromApi) {
    const String backendImageBaseUrl = "http://10.0.2.2:8080"; // Hoặc IP/domain của bạn
    if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
      return 'https://via.placeholder.com/150?Text=No+Image';
    }
    if (originalUrlFromApi.startsWith('http://') || originalUrlFromApi.startsWith('https://')) {
      if (originalUrlFromApi.contains('://localhost:8080')) {
        return originalUrlFromApi.replaceFirst('://localhost:8080', backendImageBaseUrl);
      }
      return originalUrlFromApi;
    }
    if (originalUrlFromApi.startsWith('/')) {
      return backendImageBaseUrl + originalUrlFromApi;
    }
    return '$backendImageBaseUrl/images/products/$originalUrlFromApi'; // Giả sử path mặc định
  }

  void _initializeScreenData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Điền thông tin người nhận từ AuthProvider nếu có
    if (auth.user != null) {
      _receiverNameController.text = auth.user!.fullName ?? '';
      _receiverPhoneController.text = auth.user!.phone ?? '';
      // Tạm thời chỉ điền phần đầu của địa chỉ user vào ô số nhà/đường
      // Logic parse địa chỉ đầy đủ của user để chọn Tỉnh/Huyện/Xã mặc định sẽ phức tạp hơn
      _streetAddressController.text = auth.user!.address?.split(',').first.trim() ?? '';
    }

    // Reset các lựa chọn địa chỉ và tải danh sách tỉnh nếu cần
    addressProvider.resetAddressSelectionsAndData();
    if (addressProvider.provinces.isEmpty && !addressProvider.isLoadingProvinces) {
      addressProvider.fetchProvinces();
    } else {
      _updateLocalSelectedAddressesFromProvider(); // Cập nhật UI nếu tỉnh đã có sẵn
    }

    // Reset voucher đã áp dụng và mã voucher đã nhập
    voucherProvider.removeAppliedVoucher();
    _voucherCodeController.clear();

    // Tải danh sách voucher khả dụng nếu có giỏ hàng và subtotal > 0
    if (cartProvider.cart != null && (cartProvider.cart!.cartTotalPrice ?? 0.0) > 0) {
      voucherProvider.fetchApplicableVouchers(cartProvider.cart!.cartTotalPrice!);
    }
  }

  // Cập nhật state cục bộ cho dropdown khi AddressProvider thay đổi
  void _onAddressProviderChange() {
    if (mounted) {
      setState(() {
        _currentSelectedProvince = context.read<AddressProvider>().selectedProvince;
        _currentSelectedDistrict = context.read<AddressProvider>().selectedDistrict;
        _currentSelectedWard = context.read<AddressProvider>().selectedWard;
      });
    }
  }

  void _updateLocalSelectedAddressesFromProvider() {
    if (mounted) {
      final addressProvider = context.read<AddressProvider>();
      setState(() {
        _currentSelectedProvince = addressProvider.selectedProvince;
        _currentSelectedDistrict = addressProvider.selectedDistrict;
        _currentSelectedWard = addressProvider.selectedWard;
      });
    }
  }

  @override
  void dispose() {
    _addressProviderListener.removeListener(_onAddressProviderChange); // Gỡ bỏ listener
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _streetAddressController.dispose();
    _voucherCodeController.dispose();
    super.dispose();
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

  // Hàm xử lý khi nhấn nút "Đặt hàng"
  void _placeOrder() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isGuest || authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng.')));
      // TODO: Điều hướng đến trang đăng nhập
      // Navigator.pushNamed(context, '/login_input');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin giao hàng.')));
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final addressProvider = context.read<AddressProvider>();
    final voucherProvider = context.read<VoucherProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giỏ hàng của bạn đang trống!')));
      return;
    }

    // Tạo đối tượng ShippingAddressModel từ form và AddressProvider
    final shippingAddressData = ShippingAddressModel(
      fullNameReceiver: _receiverNameController.text.trim(),
      phoneReceiver: _receiverPhoneController.text.trim(),
      street: _streetAddressController.text.trim(),
      wardName: addressProvider.selectedWard?.name ?? '', // Lấy tên từ provider
      districtName: addressProvider.selectedDistrict?.name ?? '', // Lấy tên từ provider
      provinceName: addressProvider.selectedProvince?.name ?? '', // Lấy tên từ provider
    );

    // Tạo danh sách CartItemInfoData từ CartProvider
    final cartItemsData = cartProvider.cart!.items.map((item) {
      return CartItemInfoData(productId: item.productId, quantity: item.quantity);
    }).toList();

    // Tạo đối tượng OrderCreateRequestData
    final orderRequest = OrderCreateRequestData(
      cartItems: cartItemsData,
      shippingAddress: shippingAddressData,
      paymentMethod: _selectedPaymentMethod,
      shippingFee: 30000.0, // Phí ship cố định
      voucherCode: voucherProvider.appliedVoucherCode, // Lấy mã voucher đang áp dụng
    );

    // Gọi API tạo đơn hàng
    final createdOrderDetail = await orderProvider.createOrder(
      cartItems: cartItemsData, // List<CartItemInfoData>
      shippingAddress: shippingAddressData, // ShippingAddressModel
      paymentMethod: _selectedPaymentMethod,
      shippingFee: 30000.0,
      voucherCode: voucherProvider.appliedVoucherCode,
    );

    if (mounted) {
      if (createdOrderDetail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đặt hàng thành công! Mã đơn hàng: ${createdOrderDetail.orderId}'), backgroundColor: Colors.green),
        );
        // TODO: Điều hướng đến trang OrderSuccessScreen hoặc OrderHistoryScreen
        // Ví dụ: Navigator.of(context).pushReplacementNamed(OrderSuccessScreen.routeName, arguments: {'orderId': createdOrderDetail.orderId});
        // Hiện tại, quay về trang chủ và chuyển sang tab đơn hàng (nếu có) hoặc tab home
        context.read<BottomNavProvider>().changeTab(0); // Chuyển về tab Home
        // Pop tất cả các màn hình hiện tại cho đến khi về màn hình Home (hoặc root)
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderProvider.errorMessage ?? 'Đặt hàng thất bại. Vui lòng thử lại.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final voucherProvider = context.watch<VoucherProvider>();
    final orderProvider = context.watch<OrderProvider>(); // Watch OrderProvider cho isLoading của nút đặt hàng

    final cart = cartProvider.cart;

    if (cart == null && cartProvider.isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Thanh toán')), body: const Center(child: CircularProgressIndicator()));
    }
    if (cart == null || cart.items.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Thanh toán')), body: _buildEmptyStateForCheckout(context));
    }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần 1: Thông tin Giao hàng
              Text('Thông tin Giao hàng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(controller: _receiverNameController, decoration: _inputDecoration('Họ tên người nhận *', prefixIcon: Iconsax.user_edit), validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _receiverPhoneController, decoration: _inputDecoration('Số điện thoại người nhận *', prefixIcon: Iconsax.call_calling), keyboardType: TextInputType.phone, validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập SĐT' : null),
              const SizedBox(height: 16),

              DropdownButtonFormField<Province>(
                value: _currentSelectedProvince,
                isExpanded: true,
                decoration: _inputDecoration("Tỉnh/Thành phố *", prefixIcon: Iconsax.map),
                hint: addressProvider.isLoadingProvinces ? const Text("Đang tải...") : const Text("Chọn Tỉnh/Thành phố"),
                items: addressProvider.provinces.map((Province p) => DropdownMenuItem<Province>(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: addressProvider.isLoadingProvinces ? null : (Province? newValue) {
                  context.read<AddressProvider>().setSelectedProvince(newValue);
                },
                validator: (v) => v == null ? 'Vui lòng chọn' : null,
              ),
              if (addressProvider.isLoadingProvinces) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),

              DropdownButtonFormField<District>(
                value: _currentSelectedDistrict,
                isExpanded: true,
                decoration: _inputDecoration("Quận/Huyện *", prefixIcon: Iconsax.buildings_2),
                hint: addressProvider.isLoadingDistricts ? const Text("Đang tải...") : const Text("Chọn Quận/Huyện"),
                disabledHint: _currentSelectedProvince == null ? const Text("Chọn Tỉnh/Thành trước") : null,
                items: _currentSelectedProvince == null || addressProvider.isLoadingDistricts ? [] : addressProvider.districts.map((District d) => DropdownMenuItem<District>(value: d, child: Text(d.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: _currentSelectedProvince == null || addressProvider.isLoadingDistricts ? null : (District? newValue) {
                  context.read<AddressProvider>().setSelectedDistrict(newValue);
                },
                validator: (v) => v == null ? 'Vui lòng chọn' : null,
              ),
              if (addressProvider.isLoadingDistricts) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),

              DropdownButtonFormField<Ward>(
                value: _currentSelectedWard,
                isExpanded: true,
                decoration: _inputDecoration("Phường/Xã *", prefixIcon: Iconsax.building_3),
                hint: addressProvider.isLoadingWards ? const Text("Đang tải...") : const Text("Chọn Phường/Xã"),
                disabledHint: _currentSelectedDistrict == null ? const Text("Chọn Quận/Huyện trước") : null,
                items: _currentSelectedDistrict == null || addressProvider.isLoadingWards ? [] : addressProvider.wards.map((Ward w) => DropdownMenuItem<Ward>(value: w, child: Text(w.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: _currentSelectedDistrict == null || addressProvider.isLoadingWards ? null : (Ward? newValue) {
                  context.read<AddressProvider>().setSelectedWard(newValue);
                },
                validator: (v) => v == null ? 'Vui lòng chọn' : null,
              ),
              if (addressProvider.isLoadingWards) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),

              TextFormField(
                controller: _streetAddressController,
                decoration: _inputDecoration('Số nhà, tên đường *', prefixIcon: Iconsax.location_tick),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập địa chỉ chi tiết' : null,
              ),
              const SizedBox(height: 24),

              // Phần 2: Tóm tắt Đơn hàng
              Text('Tóm tắt Đơn hàng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (cart.items.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items[i];
                      return ListTile(
                        dense: true,
                        leading: SizedBox(width: 50, height: 50, child: Image.network(_fixImageUrl(cartItem.productImageUrl), fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Iconsax.gallery_slash, size: 30, color: Colors.grey,))),
                        title: Text(cartItem.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('SL: ${cartItem.quantity} x ${currencyFormatter.format(cartItem.productPrice)}'),
                        trailing: Text(currencyFormatter.format(cartItem.itemTotalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16,),
                  ),
                )
              else
                const Text("Không có sản phẩm nào trong giỏ."),
              const Divider(height: 24, thickness: 1.5),

              // Phần 3: Mã giảm giá
              Text('Mã giảm giá', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildVoucherSection(context, voucherProvider, subtotal),
              const Divider(height: 24, thickness: 1.5),

              // Phần 4: Chi tiết thanh toán
              _buildPriceDetailRow('Tổng tiền hàng:', currencyFormatter.format(subtotal)),
              _buildPriceDetailRow('Phí vận chuyển:', currencyFormatter.format(shippingFee)),
              if (discountAmount > 0)
                _buildPriceDetailRow('Giảm giá voucher:', '-${currencyFormatter.format(discountAmount)}', color: Colors.green.shade700),
              const Divider(thickness: 0.5),
              _buildPriceDetailRow('Tổng cộng:', currencyFormatter.format(totalAmount), isTotal: true),
              const SizedBox(height: 24),

              // Phần 5: Phương thức thanh toán
              Text('Phương thức Thanh toán', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPaymentMethods(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).padding.bottom > 0 ? 12.0 : 20.0).copyWith(top:12.0),
        child: ElevatedButton.icon(
          icon: orderProvider.isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Icon(Iconsax.shopping_bag),
          label: Text(orderProvider.isLoading ? 'Đang đặt hàng...' : 'Đặt hàng ngay'),
          onPressed: (orderProvider.isLoading || cartProvider.isLoading || addressProvider.isLoadingProvinces || addressProvider.isLoadingDistricts || addressProvider.isLoadingWards || voucherProvider.isLoadingCheckVoucher)
              ? null
              : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherSection(BuildContext context, VoucherProvider voucherProvider, double currentSubtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _voucherCodeController,
                decoration: _inputDecoration('Nhập mã (nếu có)', prefixIcon: Iconsax.ticket_discount),
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
                  ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text(context.read<VoucherProvider>().errorMessage ?? (success ? 'Áp dụng mã thành công!' : 'Mã không hợp lệ.')), backgroundColor: success ? Colors.green : Colors.red),);
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
        // Hiển thị thông tin voucher đã áp dụng
        if (voucherProvider.appliedVoucherCode != null && voucherProvider.checkedVoucherInfo != null && voucherProvider.checkedVoucherInfo!.isValid)
          Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Đã áp dụng: ${voucherProvider.appliedVoucherCode}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,)),
                      IconButton(icon: const Icon(Iconsax.trash, color: Colors.grey, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Xóa mã đã áp dụng', onPressed: (){
                        context.read<VoucherProvider>().removeAppliedVoucher();
                        _voucherCodeController.clear();
                      })
                    ],
                  ),
                  if(voucherProvider.checkedVoucherInfo!.description != null && voucherProvider.checkedVoucherInfo!.description!.isNotEmpty)
                    Text(voucherProvider.checkedVoucherInfo!.description!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              )
          ),
        // Nút/Link để xem danh sách voucher khả dụng

        TextButton(
            onPressed: voucherProvider.isLoadingApplicableVouchers ? null : () {
              // Truyền subtotal hiện tại vào
              _showApplicableVouchersBottomSheet(context, context.read<VoucherProvider>(), currentSubtotal);
            },
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

  Widget _buildPriceDetailRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 15, fontWeight: FontWeight.bold, color: color ?? (isTotal ? Theme.of(context).colorScheme.error : Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    final paymentMethods = [
      // Đảm bảo 'disabled' được thêm vào tất cả các method nếu bạn dùng nó để kiểm tra isEnabled
      {'code': 'COD', 'name': 'Thanh toán khi nhận hàng (COD)', 'icon': Iconsax.money_send, 'disabled': false},
      {'code': 'MOMO', 'name': 'Ví Momo', 'icon': Iconsax.wallet_2, 'disabled': true},
      {'code': 'VNPAY', 'name': 'Cổng thanh toán VNPay', 'icon': Iconsax.card, 'disabled': true},
      {'code': 'CARD', 'name': 'Thẻ tín dụng/ghi nợ', 'icon': Iconsax.card_pos, 'disabled': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Đảm bảo các Card canh lề trái
      children: paymentMethods.map((method) {
        // ✅ Lấy giá trị từ map một cách an toàn
        final String methodCode = method['code'] as String? ?? 'UNKNOWN_CODE';
        final String methodName = method['name'] as String? ?? 'Phương thức không xác định';
        final IconData? methodIcon = method['icon'] as IconData?;
        final bool isEnabled = !(method['disabled'] as bool? ?? false);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5.0), // Tăng khoảng cách dọc một chút
          elevation: _selectedPaymentMethod == methodCode ? 1.5 : 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Bo tròn hơn một chút
            side: BorderSide(
              color: _selectedPaymentMethod == methodCode
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: _selectedPaymentMethod == methodCode ? 1.5 : 1,
            ),
          ),
          child: RadioListTile<String>(
            title: Text(
                methodName, // Sử dụng biến đã xử lý null
                style: TextStyle(
                  fontWeight: _selectedPaymentMethod == methodCode ? FontWeight.bold : FontWeight.normal,
                  color: isEnabled ? Colors.black87 : Colors.grey.shade500, // Màu chữ khi disable
                )
            ),
            value: methodCode, // Sử dụng biến đã xử lý null
            groupValue: _selectedPaymentMethod,
            onChanged: isEnabled
                ? (String? value) {
              if (value != null) {
                setState(() => _selectedPaymentMethod = value);
              }
            }
                : null, // Nút bị vô hiệu hóa nếu isEnabled là false
            secondary: methodIcon != null
                ? Icon(methodIcon, color: isEnabled ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, size: 26)
                : null,
            activeColor: Theme.of(context).colorScheme.primary,
            controlAffinity: ListTileControlAffinity.trailing, // Radio button ở bên phải
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Điều chỉnh padding
          ),
        );
      }).toList(),
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
                context.read<BottomNavProvider>().changeTab(0);
                if (Navigator.canPop(context)) { Navigator.of(context).pop(); }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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

// HÀM HIỂN THỊ BOTTOM SHEET CHO DANH SÁCH VOUCHER
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
                        } else if (!success && context.read<VoucherProvider>().appliedVoucherCode == null) {
                          // _voucherCodeController.clear(); // Cân nhắc không xóa nếu áp dụng thất bại
                        }
                      }
                    },
                  );
                },
              );
            }

            // Cho phép cuộn và thay đổi kích thước bottom sheet
            return DraggableScrollableSheet(
                initialChildSize: 0.5, // Chiều cao ban đầu (50% màn hình)
                minChildSize: 0.3,    // Chiều cao tối thiểu
                maxChildSize: 0.85,   // Chiều cao tối đa
                expand: false,
                builder: (_, scrollController) {
                  return Container(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center( // Thanh kéo nhỏ ở trên cùng
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
  // HÀM HIỂN THỊ BOTTOM SHEET CHO DANH SÁCH VOUCHER
}