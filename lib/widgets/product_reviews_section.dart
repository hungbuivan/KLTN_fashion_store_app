import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../providers/product_review_provider.dart';
import '../../models/review_model.dart';
import '../../models/product_detail_model.dart';
import '../../screens/all_reviews_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductReviewProvider>(context, listen: false)
          .fetchReviews(widget.product.id);
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

        // Tiêu đề + nút Xem tất cả
        Consumer<ProductReviewProvider>(
          builder: (context, provider, child) {
            final double averageRating = provider.averageRating ?? 0.0;
            final int totalReviews = provider.totalReviews ?? 0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Đánh giá sản phẩm",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
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
        Consumer<ProductReviewProvider>(
          builder: (context, provider, child) {
            final double avg = provider.averageRating ?? 0.0;
            final int total = provider.totalReviews ?? 0;

            return Row(
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRating(avg),
                    Text('Dựa trên $total đánh giá',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Danh sách đánh giá (giới hạn 3 cái)
        Consumer<ProductReviewProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.reviews.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('Chưa có đánh giá nào cho sản phẩm này.')),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.reviews.length > 3 ? 3 : provider.reviews.length,
              itemBuilder: (context, index) =>
                  _buildReviewCard(provider.reviews[index]),
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
        icon = Iconsax.star_1;
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
                  Text(DateFormat('dd/MM/yyyy').format(review.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
