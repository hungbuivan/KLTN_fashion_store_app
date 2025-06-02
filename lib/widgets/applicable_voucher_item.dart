// file: lib/widgets/checkout/applicable_voucher_item.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // Import intl cho NumberFormat
import '../../models/voucher_model.dart'; // Import VoucherModel

// Hàm format tiền tệ cục bộ (nếu không có global formatter)
// Hoặc bạn có thể import currencyFormatter từ utils của bạn
String _formatCurrencyForItem(double? value) {
  if (value == null) return "N/A";
  final NumberFormat currencyFormatter = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0, name: '');
  return currencyFormatter.format(value) + " VNĐ";
}

class ApplicableVoucherItem extends StatelessWidget {
  final VoucherModel voucher;
  final VoidCallback onTap; // Callback khi voucher được chọn
  final bool isCurrentlyApplied; // Kiểm tra xem voucher này có đang được áp dụng không

  const ApplicableVoucherItem({
    super.key,
    required this.voucher,
    required this.onTap,
    this.isCurrentlyApplied = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sử dụng getter isValidNow từ VoucherModel để kiểm tra hiệu lực
    final bool canUse = voucher.isValidNow;

    return Opacity(
      opacity: canUse ? 1.0 : 0.6, // Làm mờ hơn nếu không còn hiệu lực
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
        elevation: isCurrentlyApplied ? 2.5 : 0.8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isCurrentlyApplied
                ? theme.colorScheme.primary
                : (canUse ? Colors.grey.shade300 : Colors.grey.shade400),
            width: isCurrentlyApplied ? 1.8 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(
            voucher.discountType == DiscountTypeModel.PERCENTAGE
                ? Iconsax.percentage_square5
                : Iconsax.money_recive5, // Sử dụng icon filled nếu có
            color: canUse
                ? (isCurrentlyApplied ? theme.colorScheme.primary : theme.colorScheme.secondary)
                : Colors.grey.shade500,
            size: 38,
          ),
          title: Text(
            voucher.code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: canUse ? (isCurrentlyApplied ? theme.colorScheme.primary : Colors.black87) : Colors.grey.shade600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Text(
                voucher.description ?? voucher.discountDisplay, // Ưu tiên description
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: canUse ? Colors.black54 : Colors.grey.shade500),
              ),
              const SizedBox(height: 5),
              Text(
                voucher.minOrderConditionDisplay, // Điều kiện đơn hàng tối thiểu
                style: TextStyle(fontSize: 12, color: canUse ? Colors.orange.shade800 : Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              if (!canUse)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    voucher.isActive ? "Đã hết hạn hoặc chưa tới ngày" : "Không hoạt động",
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontStyle: FontStyle.italic),
                  ),
                )
              else if (voucher.endDate != null) // Hiển thị ngày hết hạn nếu còn hiệu lực
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    "HSD: ${DateFormat('dd/MM/yyyy HH:mm').format(voucher.endDate!)}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
            ],
          ),
          trailing: isCurrentlyApplied
              ? Icon(Iconsax.tick_circle5, color: Colors.green.shade700, size: 26) // Icon filled
              : (canUse ? Icon(Iconsax.arrow_right_3, color: theme.colorScheme.primary.withOpacity(0.8), size: 22) : null),
          onTap: canUse ? onTap : null, // Chỉ cho phép nhấn nếu voucher còn hiệu lực
          tileColor: isCurrentlyApplied ? theme.colorScheme.primary.withOpacity(0.05) : null,
        ),
      ),
    );
  }
}