// file: lib/screens/add_review_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// Import các provider, model và tiện ích cần thiết
import '../models/order_item_model.dart';
import '../providers/product_review_provider.dart';
// Để dùng OrderItemModel
import '../utils/formatter.dart';

class AddReviewScreen extends StatefulWidget {
  final int orderId;
  final OrderItemModel productToReview;

  const AddReviewScreen({
    super.key,
    required this.orderId,
    required this.productToReview,
  });

  static const routeName = '/add-review';

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0; // Điểm đánh giá ban đầu

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _fixImageUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/150';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/products/$url';
  }

  Future<void> _submitReview() async {
    final provider = context.read<ProductReviewProvider>();
    final success = await provider.submitReview(
      productId: widget.productToReview.productId!,
      orderId: widget.orderId,
      rating: _rating.toInt(),
      comment: _commentController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá sản phẩm!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Trả về true để màn hình trước biết và tải lại dữ liệu
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Gửi đánh giá thất bại.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viết đánh giá'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin sản phẩm đang được đánh giá
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.network(_fixImageUrl(widget.productToReview.productImageUrl), width: 60, height: 60, fit: BoxFit.cover),
              title: Text(widget.productToReview.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(currencyFormatter.format(widget.productToReview.priceAtPurchase)),
            ),
            const Divider(height: 30),

            // Phần chấm điểm sao
            Center(
              child: Column(
                children: [
                  Text('Bạn cảm thấy sản phẩm này thế nào?', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(Iconsax.star1, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Phần bình luận
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Chia sẻ cảm nhận của bạn',
                hintText: 'Sản phẩm này có tốt không? Bạn có thích nó không?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Nút Gửi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: provider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gửi đánh giá'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
