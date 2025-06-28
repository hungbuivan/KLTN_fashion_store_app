// file: lib/widgets/product/product_reviews_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../providers/product_review_provider.dart';
import '../../models/review_model.dart';
import '../../models/product_detail_model.dart';
import '../screens/all_reviews_screen.dart'; // Để lấy thông tin rating trung bình

class ProductReviewsSection extends StatefulWidget {
  final ProductDetailModel product;

  const ProductReviewsSection({super.key, required this.product});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  @override
  void initState() {
    super.initState();
    // Tải các đánh giá lần đầu tiên khi widget được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductReviewProvider>(context, listen: false).fetchReviews(widget.product.id);
    });
  }

  String _fixAvatarUrl(String? url) {
    const String serverBase = "http://10.0.2.2:8080";
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return serverBase + url;
    return '$serverBase/images/avatars/$url';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Consumer<ProductReviewProvider>(
          builder: (context, provider, child) {
            double averageRating = provider.reviews.isEmpty
                ? 0.0
                : provider.reviews
                .map((e) => e.rating)
                .reduce((a, b) => a + b) /
                provider.reviews.length;

            int totalReviews = provider.reviews.length;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Đánh giá sản phẩm",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllReviewsScreen(
                          productId: widget.product.id,
                          productName: widget.product.name,
                          initialAverageRating: averageRating,
                          initialTotalReviews: totalReviews,
                        ),
                      ),
                    );
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 8),

        // Phần hiển thị rating tổng quan
        Row(
          children: [
            Text(
              widget.product.averageRating?.toStringAsFixed(1) ?? '0.0',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStarRating(widget.product.averageRating ?? 0.0),
                Text('Dựa trên ${widget.product.totalReviews ?? 0} đánh giá', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Danh sách các đánh giá
        Consumer<ProductReviewProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.reviews.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.reviews.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('Chưa có đánh giá nào cho sản phẩm này.'),
              ));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.reviews.length > 3 ? 3 : provider.reviews.length, // Chỉ hiển thị tối đa 3 review
              itemBuilder: (context, index) {
                return _buildReviewCard(provider.reviews[index]);
              },
              separatorBuilder: (context, index) => const Divider(height: 25),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStarRating(double rating, {double size = 20}) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      IconData icon;
      if (i <= rating) {
        icon = Iconsax.star1;
      } else if (i - 0.5 <= rating) {
        icon = Iconsax.star_1; // Flutter's Iconsax might not have half-star, using full star as fallback
      } else {
        icon = Iconsax.star;
      }
      stars.add(Icon(icon, color: Colors.amber, size: size));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(_fixAvatarUrl(review.userAvatarUrl)),
              onBackgroundImageError: (_, __) {},
              child: review.userAvatarUrl == null || review.userAvatarUrl!.isEmpty
                  ? const Icon(Iconsax.user, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('dd/MM/yyyy').format(review.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            _buildStarRating(review.rating.toDouble(), size: 16),
          ],
        ),
        const SizedBox(height: 8),
        if (review.comment != null && review.comment!.isNotEmpty)
          Text(review.comment!, style: TextStyle(color: Colors.grey[800], height: 1.4)),
      ],
    );
  }
}
