// file: lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/address_models.dart';
import '../../providers/address_provider.dart';
import '../../providers/signup_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  Province? _currentSelectedProvince;
  District? _currentSelectedDistrict;
  Ward? _currentSelectedWard;

  late AddressProvider _addressProviderListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SignupProvider>(context, listen: false).resetState();
      _addressProviderListener = Provider.of<AddressProvider>(context, listen: false);
      _addressProviderListener.addListener(_onAddressProviderChange);
      _addressProviderListener.resetAddressSelectionsAndData();
      if (_addressProviderListener.provinces.isEmpty && !_addressProviderListener.isLoadingProvinces) {
        _addressProviderListener.fetchProvinces();
      } else {
        _updateLocalSelectedAddresses();
      }
    });
  }

  void _onAddressProviderChange() {
    if (mounted) {
      setState(() {
        _currentSelectedProvince = _addressProviderListener.selectedProvince;
        _currentSelectedDistrict = _addressProviderListener.selectedDistrict;
        _currentSelectedWard = _addressProviderListener.selectedWard;
      });
    }
  }

  void _updateLocalSelectedAddresses() {
    if (mounted) {
      setState(() {
        _currentSelectedProvince = _addressProviderListener.selectedProvince;
        _currentSelectedDistrict = _addressProviderListener.selectedDistrict;
        _currentSelectedWard = _addressProviderListener.selectedWard;
      });
    }
  }

  @override
  void dispose() {
    _addressProviderListener.removeListener(_onAddressProviderChange);
    super.dispose();
  }

  void _trySubmit(BuildContext context) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    FocusScope.of(context).unfocus();

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ và chính xác các thông tin bắt buộc.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    _formKey.currentState?.save();

    final signupProvider = Provider.of<SignupProvider>(context, listen: false);

    final success = await signupProvider.signupUser(
      provinceName: _currentSelectedProvince?.name,
      districtName: _currentSelectedDistrict?.name,
      wardName: _currentSelectedWard?.name,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(signupProvider.message ?? 'Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(signupProvider.message ?? 'Đăng ký thất bại. Vui lòng thử lại.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String labelText, IconData prefixIcon, {Widget? suffixIcon, String? hintText, Color? prefixIconColor}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText ?? 'Nhập $labelText',
      prefixIcon: Icon(prefixIcon, size: 20, color: prefixIconColor ?? Colors.grey[700]),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none), // Bỏ border mặc định
      filled: true, // Để có thể set fillColor
      fillColor: Colors.white.withOpacity(0.9), // Màu nền cho TextField
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final signupProvider = context.watch<SignupProvider>();
    final addressProvider = context.watch<AddressProvider>();

    final Color gradientStartColor = Colors.blue.shade900; // Màu gradient giống LoginScreen
    final Color gradientEndColor = Colors.blue.shade400;   // Màu gradient giống LoginScreen
    final Color primaryActionColor = Colors.blue.shade700; // Màu nút chính

    return Scaffold(
      body: Stack( // Sử dụng Stack để đặt AppBar tùy chỉnh lên trên nền gradient
        children: [
          // Phần nền Gradient
          Container(
            width: double.infinity,
            height: double.infinity, // Chiếm hết màn hình
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter, // Có thể điều chỉnh end để gradient mềm hơn
                colors: [
                  gradientStartColor,
                  Colors.blue.shade800, // Màu ở giữa giống LoginScreen
                  gradientEndColor
                ],
              ),
            ),
            child: Column( // Column cho phần header text (Hello, Welcome...)
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).padding.top + 60), // Khoảng trống cho status bar và nút back
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Create Account", // Tiêu đề
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Join us and start your fashion journey!", // Mô tả ngắn
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // Không cần SizedBox(height: 20) ở đây vì Expanded sẽ đẩy form xuống
              ],
            ),
          ),

          // Phần Form nội dung (màu trắng, bo góc trên)
          Positioned.fill(
            top: MediaQuery.of(context).padding.top + 160, // Điều chỉnh vị trí bắt đầu của form
            // (sau phần text "Create Account")
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white, // Màu nền của form
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40), // Bo góc giống LoginScreen
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 30, 30, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Các trường TextFormField
                      TextFormField(controller: signupProvider.fullNameController, decoration: _inputDecoration("Họ và tên *", Iconsax.user_edit, prefixIconColor: Colors.grey.shade700), keyboardType: TextInputType.name, textCapitalization: TextCapitalization.words, validator: (value) { if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ và tên.'; if (value.trim().length < 2) return 'Họ tên phải có ít nhất 2 ký tự.'; return null; }),
                      const SizedBox(height: 16),
                      TextFormField(controller: signupProvider.emailController, decoration: _inputDecoration("Email *", Iconsax.sms, prefixIconColor: Colors.grey.shade700), keyboardType: TextInputType.emailAddress, validator: (value) { if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email.'; if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value.trim())) return 'Định dạng email không hợp lệ.'; return null; }),
                      const SizedBox(height: 16),
                      TextFormField(controller: signupProvider.passwordController, obscureText: signupProvider.hidePassword, decoration: _inputDecoration("Mật khẩu *", Iconsax.key, prefixIconColor: Colors.grey.shade700, suffixIcon: IconButton(icon: Icon(signupProvider.hidePassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[600]), onPressed: context.read<SignupProvider>().toggleHidePassword)), validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.'; if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.'; return null; }),
                      const SizedBox(height: 16),
                      TextFormField(controller: signupProvider.confirmPasswordController, obscureText: signupProvider.hideConfirmPassword, decoration: _inputDecoration("Xác nhận mật khẩu *", Iconsax.key, prefixIconColor: Colors.grey.shade700, suffixIcon: IconButton(icon: Icon(signupProvider.hideConfirmPassword ? Iconsax.eye_slash : Iconsax.eye, color: Colors.grey[600]), onPressed: context.read<SignupProvider>().toggleHideConfirmPassword)), validator: (value) { if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu.'; if (value != signupProvider.passwordController.text) return 'Mật khẩu xác nhận không khớp.'; return null; }),
                      const SizedBox(height: 16),
                      TextFormField(controller: signupProvider.phoneController, decoration: _inputDecoration("Số điện thoại", Iconsax.call_calling, prefixIconColor: Colors.grey.shade700), keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(value: signupProvider.selectedGender, decoration: _inputDecoration("Giới tính", Iconsax.man, prefixIconColor: Colors.grey.shade700), items: [const DropdownMenuItem<String>(value: null, child: Text("Chọn giới tính (tùy chọn)")), const DropdownMenuItem<String>(value: 'male', child: Text("Nam")), const DropdownMenuItem<String>(value: 'female', child: Text("Nữ")), const DropdownMenuItem<String>(value: 'other', child: Text("Khác")),], onChanged: (String? newValue) => context.read<SignupProvider>().setSelectedGender(newValue)),
                      const SizedBox(height: 24),

                      const Text("Địa chỉ nhận hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<Province>(
                        value: _currentSelectedProvince,
                        isExpanded: true,
                        decoration: _inputDecoration("Tỉnh/Thành phố *", Iconsax.map, prefixIconColor: Colors.grey.shade700),
                        hint: addressProvider.isLoadingProvinces ? const Text("Đang tải...") : const Text("Chọn Tỉnh/Thành phố"),
                        items: addressProvider.isLoadingProvinces ? [] : addressProvider.provinces.map((Province province) => DropdownMenuItem<Province>(value: province, child: Text(province.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: addressProvider.isLoadingProvinces ? null : (Province? newValue) => context.read<AddressProvider>().setSelectedProvince(newValue),
                        validator: (value) => value == null ? 'Vui lòng chọn Tỉnh/Thành phố' : null,
                      ),
                      if (addressProvider.isLoadingProvinces) const Padding(padding: EdgeInsets.only(top: 8.0), child: LinearProgressIndicator(minHeight: 2)),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<District>(
                        value: _currentSelectedDistrict,
                        isExpanded: true,
                        decoration: _inputDecoration("Quận/Huyện *", Iconsax.buildings_2, prefixIconColor: Colors.grey.shade700),
                        hint: addressProvider.isLoadingDistricts ? const Text("Đang tải...") : const Text("Chọn Quận/Huyện"),
                        disabledHint: addressProvider.selectedProvince == null ? const Text("Chọn Tỉnh/Thành trước") : (addressProvider.isLoadingDistricts ? const Text("Đang tải...") : null),
                        items: addressProvider.selectedProvince == null || addressProvider.isLoadingDistricts ? [] : addressProvider.districts.map((District district) => DropdownMenuItem<District>(value: district, child: Text(district.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: addressProvider.selectedProvince == null || addressProvider.isLoadingDistricts ? null : (District? newValue) => context.read<AddressProvider>().setSelectedDistrict(newValue),
                        validator: (value) => value == null ? 'Vui lòng chọn Quận/Huyện' : null,
                      ),
                      if (addressProvider.isLoadingDistricts) const Padding(padding: EdgeInsets.only(top: 8.0), child: LinearProgressIndicator(minHeight: 2)),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Ward>(
                        value: _currentSelectedWard,
                        isExpanded: true,
                        decoration: _inputDecoration("Phường/Xã *", Iconsax.building_3, prefixIconColor: Colors.grey.shade700),
                        hint: addressProvider.isLoadingWards ? const Text("Đang tải...") : const Text("Chọn Phường/Xã"),
                        disabledHint: addressProvider.selectedDistrict == null ? const Text("Chọn Quận/Huyện trước") : (addressProvider.isLoadingWards ? const Text("Đang tải...") : null),
                        items: addressProvider.selectedDistrict == null || addressProvider.isLoadingWards ? [] : addressProvider.wards.map((Ward ward) => DropdownMenuItem<Ward>(value: ward, child: Text(ward.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: addressProvider.selectedDistrict == null || addressProvider.isLoadingWards ? null : (Ward? newValue) => context.read<AddressProvider>().setSelectedWard(newValue),
                        validator: (value) => value == null ? 'Vui lòng chọn Phường/Xã' : null,
                      ),
                      if (addressProvider.isLoadingWards) const Padding(padding: EdgeInsets.only(top: 8.0), child: LinearProgressIndicator(minHeight: 2)),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: signupProvider.streetAddressController,
                        decoration: _inputDecoration("Số nhà, tên đường *", Iconsax.map_1, prefixIconColor: Colors.grey.shade700),
                        keyboardType: TextInputType.streetAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số nhà, tên đường.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      if (signupProvider.message != null && !signupProvider.isLoading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            signupProvider.message!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      ElevatedButton(
                        onPressed: signupProvider.isLoading || addressProvider.isLoadingProvinces || addressProvider.isLoadingDistricts || addressProvider.isLoadingWards
                            ? null // Disable nút khi đang loading
                            : () => _trySubmit(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryActionColor,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)), // Bo tròn hơn
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: signupProvider.isLoading || addressProvider.isLoadingProvinces || addressProvider.isLoadingDistricts || addressProvider.isLoadingWards
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2.5))
                            : Text("Sign Up", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ", style: TextStyle(color: Colors.grey[700])),
                          GestureDetector(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(color: primaryActionColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nút Back tùy chỉnh ở góc trên bên trái (nếu không dùng AppBar mặc định)
          Positioned(
            top: MediaQuery.of(context).padding.top + 5, // Khoảng cách từ đỉnh status bar
            left: 10,
            child: Material( // Bọc IconButton bằng Material để có hiệu ứng splash
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
                tooltip: 'Quay lại',
              ),
            ),
          ),
        ],
      ),
    );
  }
}