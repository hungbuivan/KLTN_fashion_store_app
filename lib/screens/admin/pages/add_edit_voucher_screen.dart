// file: lib/screens/admin/pages/add_edit_voucher_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Cho FilteringTextInputFormatter
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // Để format ngày tháng

// Đảm bảo các đường dẫn import này đúng với cấu trúc thư mục của bạn
//import '../../../providers/admin/voucher_admin_provider.dart';
import '../../../models/voucher_model.dart';
import '../../../providers/voucher_admin_provider.dart'; // Import VoucherModel để có DiscountTypeModel

class AddEditVoucherScreen extends StatefulWidget {
  final VoucherModel? voucher; // Null nếu là tạo mới, có giá trị nếu là sửa

  const AddEditVoucherScreen({super.key, this.voucher});

  @override
  State<AddEditVoucherScreen> createState() => _AddEditVoucherScreenState();
}

class _AddEditVoucherScreenState extends State<AddEditVoucherScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường input
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountValueController = TextEditingController();
  final TextEditingController _minOrderValueController = TextEditingController();
  final TextEditingController _maxDiscountAmountController = TextEditingController();
  final TextEditingController _usageLimitController = TextEditingController();
  final TextEditingController _usageLimitPerUserController = TextEditingController();

  // State cho các trường không phải text
  DiscountTypeModel? _selectedDiscountType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;

  bool _isSaving = false; // Để hiển thị loading trên nút Lưu

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ sửa, điền dữ liệu của voucher vào các controller
    if (widget.voucher != null) {
      final v = widget.voucher!;
      _codeController.text = v.code;
      _descriptionController.text = v.description ?? '';
      _selectedDiscountType = v.discountType;
      _discountValueController.text = v.discountValue.toStringAsFixed(0);
      _minOrderValueController.text = v.minOrderValue?.toStringAsFixed(0) ?? '';
      _maxDiscountAmountController.text = v.maxDiscountAmount?.toStringAsFixed(0) ?? '';
      _usageLimitController.text = v.usageLimitPerVoucher?.toString() ?? '';
      _usageLimitPerUserController.text = v.usageLimitPerUser?.toString() ?? '';
      _startDate = v.startDate;
      _endDate = v.endDate;
      _isActive = v.isActive;
    }
  }

  @override
  void dispose() {
    // Dispose tất cả các controller để tránh rò rỉ bộ nhớ
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderValueController.dispose();
    _maxDiscountAmountController.dispose();
    _usageLimitController.dispose();
    _usageLimitPerUserController.dispose();
    super.dispose();
  }

  // Hàm helper cho InputDecoration
  InputDecoration _inputDecoration(String label, {String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: Colors.grey[700]) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  // Hàm chọn ngày
  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Nếu ngày bắt đầu sau ngày kết thúc, reset ngày kết thúc
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Hàm xử lý khi nhấn nút Lưu
  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();

    setState(() { _isSaving = true; });

    final provider = context.read<VoucherAdminProvider>();

    // Tạo Map dữ liệu để gửi lên API
    final Map<String, dynamic> voucherData = {
      // Chỉ gửi 'code' khi tạo mới. Backend thường không cho sửa code.
      if (widget.voucher == null) 'code': _codeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim(),
      'discountType': _selectedDiscountType.toString().split('.').last, // Gửi dạng String: "PERCENTAGE" hoặc "FIXED_AMOUNT"
      'discountValue': double.tryParse(_discountValueController.text),
      'minOrderValue': _minOrderValueController.text.isEmpty ? null : double.tryParse(_minOrderValueController.text),
      'maxDiscountAmount': _maxDiscountAmountController.text.isEmpty ? null : double.tryParse(_maxDiscountAmountController.text),
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'usageLimitPerVoucher': _usageLimitController.text.isEmpty ? null : int.tryParse(_usageLimitController.text),
      'usageLimitPerUser': _usageLimitPerUserController.text.isEmpty ? null : int.tryParse(_usageLimitPerUserController.text),
      'isActive': _isActive,
    };

    bool success = false;
    try {
      if (widget.voucher == null) { // Chế độ tạo mới
        final createdVoucher = await provider.createVoucher(voucherData);
        success = createdVoucher != null;
      } else { // Chế độ sửa
        final updatedVoucher = await provider.updateVoucher(widget.voucher!.id!, voucherData);
        success = updatedVoucher != null;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lưu voucher thành công!'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true); // Trả về true để màn hình danh sách biết cần tải lại
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? 'Lưu voucher thất bại.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // DateFormat từ package intl
    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.voucher == null ? 'Tạo Voucher Mới' : 'Sửa Voucher'),
        actions: [
          IconButton(
            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Icon(Iconsax.save_2),
            onPressed: _isSaving ? null : _saveForm,
            tooltip: 'Lưu Voucher',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: _inputDecoration('Mã Voucher *', hint: 'Ví dụ: SUMMER20', prefixIcon: Iconsax.ticket),
                textCapitalization: TextCapitalization.characters,
                enabled: widget.voucher == null, // Chỉ cho phép nhập khi tạo mới
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Mã không được để trống.';
                  if (value.contains(' ')) return 'Mã không được chứa khoảng trắng.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Mô tả', hint: 'Ví dụ: Giảm giá mùa hè', prefixIcon: Iconsax.document_text),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sử dụng Flexible thay vì Expanded để tránh lỗi overflow
                  Flexible(
                    flex: 3,
                    child: DropdownButtonFormField<DiscountTypeModel>(
                      value: _selectedDiscountType,
                      isExpanded: true,
                      decoration: _inputDecoration('Loại giảm giá *'),
                      hint: const Text('Chọn loại'),
                      items: DiscountTypeModel.values.where((type) => type != DiscountTypeModel.UNKNOWN).map((type) {
                        return DropdownMenuItem<DiscountTypeModel>(
                          value: type,
                          child: Text(
                            type == DiscountTypeModel.PERCENTAGE ? 'Theo %' : 'Tiền cố định',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() { _selectedDiscountType = value; });
                      },
                      validator: (value) => value == null ? 'Vui lòng chọn loại' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 2,
                    child: TextFormField(
                      controller: _discountValueController,
                      decoration: _inputDecoration('Giá trị *', prefixIcon: Iconsax.money_recive),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Nhập giá trị.';
                        if (double.tryParse(value) == null) return 'Không hợp lệ.';
                        if (_selectedDiscountType == DiscountTypeModel.PERCENTAGE && (double.parse(value) <= 0 || double.parse(value) > 100)) {
                          return 'Phải từ 1-100';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: TextFormField(controller: _minOrderValueController, decoration: _inputDecoration('Đơn hàng tối thiểu', hint: 'Bỏ trống nếu không có', prefixIcon: Iconsax.shopping_cart), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _maxDiscountAmountController, decoration: _inputDecoration('Giảm tối đa', hint: 'Bỏ trống nếu không có', prefixIcon: Iconsax.money_forbidden), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(readOnly: true, decoration: _inputDecoration('Ngày bắt đầu *', prefixIcon: Iconsax.calendar_add), controller: TextEditingController(text: _startDate == null ? '' : formatter.format(_startDate!)), onTap: () => _selectDate(context, isStartDate: true), validator: (value) => _startDate == null ? 'Vui lòng chọn ngày.' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(readOnly: true, decoration: _inputDecoration('Ngày kết thúc *', prefixIcon: Iconsax.calendar_remove), controller: TextEditingController(text: _endDate == null ? '' : formatter.format(_endDate!)), onTap: () => _selectDate(context, isStartDate: false), validator: (value) { if (_endDate == null) return 'Vui lòng chọn ngày.'; if (_startDate != null && !_endDate!.isAfter(_startDate!)) return 'Phải sau ngày bắt đầu.'; return null; })),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: TextFormField(controller: _usageLimitController, decoration: _inputDecoration('Giới hạn lượt dùng', hint: 'Bỏ trống nếu không giới hạn', prefixIcon: Iconsax.receipt_1), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _usageLimitPerUserController, decoration: _inputDecoration('Lượt/Người dùng', hint: 'Mặc định là 1', prefixIcon: Iconsax.user_octagon), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Kích hoạt Voucher'),
                subtitle: const Text('Cho phép người dùng sử dụng voucher này.'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() { _isActive = value; });
                },
                secondary: Icon(_isActive ? Iconsax.unlock : Iconsax.lock_1, color: _isActive ? Colors.green : Colors.grey),
                activeColor: Colors.green,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.save_2),
                  label: Text(widget.voucher == null ? 'Tạo Voucher' : 'Cập nhật'),
                  onPressed: _isSaving ? null : _saveForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}