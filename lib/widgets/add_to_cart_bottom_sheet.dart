// file: lib/widgets/add_to_cart_bottom_sheet.dart
import 'package:fashion_store_app/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../models/product_detail_model.dart';

// Các hàm helper (bạn có thể đưa vào file utils chung)
// final currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0, name: '');
//
// String _formatCurrency(double? value) {
//   if (value == null) return "N/A";
//   return currencyFormatter.format(value);
// }

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

class AddToCartBottomSheet extends StatefulWidget {
  final ProductDetailModel product;

  const AddToCartBottomSheet({super.key, required this.product});

  @override
  State<AddToCartBottomSheet> createState() => _AddToCartBottomSheetState();
}

class _AddToCartBottomSheetState extends State<AddToCartBottomSheet> {
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Tự động chọn giá trị đầu tiên nếu chỉ có một lựa chọn
    if (widget.product.availableSizes.length == 1) {
      _selectedSize = widget.product.availableSizes.first;
    }
    if (widget.product.availableColors.length == 1) {
      _selectedColor = widget.product.availableColors.first;
    }
  }

  // Hàm kiểm tra xem người dùng đã chọn đủ các tùy chọn bắt buộc chưa
  bool _canAddToCart() {
    bool sizeOk = widget.product.availableSizes.isEmpty || _selectedSize != null;
    bool colorOk = widget.product.availableColors.isEmpty || _selectedColor != null;
    return sizeOk && colorOk;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canAddToCart = _canAddToCart();

    // ✅ SỬA Ở ĐÂY: Thêm decoration vào Container cha
    return Container(
      // Padding để tránh bàn phím che mất nội dung
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      // Thêm decoration để có nền trắng và bo góc trên
      decoration: BoxDecoration(
        color: theme.canvasColor, // Lấy màu nền từ theme (thường là màu trắng)
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Để BottomSheet chỉ chiếm chiều cao cần thiết
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ảnh, Tên, Giá, Kho
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _fixImageUrl(widget.product.imageUrl?.isNotEmpty == true ? widget.product.imageUrl : null),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 90, height: 90,
                    color: Colors.grey[200],
                    child: const Icon(Iconsax.gallery_slash, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(widget.product.price),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kho: ${widget.product.stock ?? 0}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // Phần chọn Màu sắc (nếu có)
          if (widget.product.availableColors.isNotEmpty) ...[
            Text('Màu sắc', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildVariantChips(
              choices: widget.product.availableColors,
              selectedChoice: _selectedColor,
              onSelected: (value) {
                setState(() { _selectedColor = value; });
              },
            ),
            const SizedBox(height: 24),
          ],

          // Phần chọn Size (nếu có)
          if (widget.product.availableSizes.isNotEmpty) ...[
            Text('Kích thước', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildVariantChips(
              choices: widget.product.availableSizes,
              selectedChoice: _selectedSize,
              onSelected: (value) {
                setState(() { _selectedSize = value; });
              },
            ),
            const SizedBox(height: 24),
          ],

          // Phần chọn Số lượng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số lượng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              _buildQuantitySelector(),
            ],
          ),

          const SizedBox(height: 24),

          // Nút Thêm vào giỏ hàng
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.shopping_bag),
              label: const Text('Thêm vào giỏ hàng'),
              onPressed: canAddToCart
                  ? () {
                // Trả về kết quả cho màn hình gọi nó
                Navigator.pop(context, {
                  'quantity': _quantity,
                  'size': _selectedSize,
                  'color': _selectedColor,
                });
              }
                  : null, // Vô hiệu hóa nút nếu chưa chọn đủ
              style: ElevatedButton.styleFrom(
                backgroundColor: canAddToCart ? const Color(0xFFEE4D2D) : Colors.grey.shade400, // Màu cam/đỏ giống Shopee
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper cho việc chọn size/màu
  Widget _buildVariantChips({
    required List<String> choices,
    required String? selectedChoice,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: choices.map((choice) {
        final isSelected = selectedChoice == choice;
        return ChoiceChip(
          label: Text(choice),
          selected: isSelected,
          onSelected: (selected) {
            onSelected(choice); // Luôn chọn, không cho bỏ chọn
          },
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFFEE4D2D) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          selectedColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? const Color(0xFFEE4D2D) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }

  // Widget helper cho bộ chọn số lượng
  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Iconsax.minus, size: 20),
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade300),
                  right: BorderSide(color: Colors.grey.shade300),
                )
            ),
            child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Iconsax.add, size: 20),
            onPressed: () {
              // TODO: Kiểm tra với số lượng tồn kho của variant đã chọn
              // if (_quantity < stockOfSelectedVariant)
              setState(() { _quantity++; });
            },
          ),
        ],
      ),
    );
  }
}