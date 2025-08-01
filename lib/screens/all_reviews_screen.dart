import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../providers/product_review_provider.dart';
import '../models/review_model.dart';

class AllReviewsScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final double initialAverageRating;
  final int initialTotalReviews;

  const AllReviewsScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.initialAverageRating,
    required this.initialTotalReviews,
  });

  static const routeName = '/all-reviews';

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshReviews();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<ProductReviewProvider>(context, listen: false);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      if (provider.pageData != null && !provider.pageData!.last && !provider.isLoading) {
        provider.fetchReviews(widget.productId, page: provider.pageData!.number + 1);
      }
    }
  }

  Future<void> _refreshReviews() async {
    await Provider.of<ProductReviewProvider>(context, listen: false)
        .fetchReviews(widget.productId, page: 0);
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Đánh giá cho ${widget.productName}'),
        centerTitle: true,
      ),
      body: Consumer<ProductReviewProvider>(
        builder: (context, provider, child) {
          final double rating = provider.averageRating ?? widget.initialAverageRating;
          final int total = provider.totalReviews ?? widget.initialTotalReviews;

          if (provider.isLoading && provider.reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.reviews.isEmpty) {
            return Center(child: Text(provider.errorMessage!));
          }

          return RefreshIndicator(
            onRefresh: _refreshReviews,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Tóm tắt rating
                SliverToBoxAdapter(
                  child: _buildOverallRatingSummary(context, rating, total),
                ),

                // Danh sách đánh giá
                if (provider.reviews.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('Chưa có đánh giá nào.')),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final review = provider.reviews[index];
                        return _buildReviewCard(review, theme);
                      },
                      childCount: provider.reviews.length,
                    ),
                  ),

                // Loading khi tải thêm
                if (provider.isLoading && provider.reviews.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallRatingSummary(BuildContext context, double averageRating, int totalReviews) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: averageRating.toStringAsFixed(1),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: ' / 5',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(averageRating, size: 24),
                const SizedBox(height: 4),
                Text('$totalReviews đánh giá', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(_fixAvatarUrl(review.userAvatarUrl)),
                onBackgroundImageError: (_, __) {},
                child: (review.userAvatarUrl == null || review.userAvatarUrl!.isEmpty)
                    ? const Icon(Iconsax.user, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(review.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              Text(DateFormat('dd/MM/yyyy').format(review.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            _buildStarRating(review.rating.toDouble(), size: 16),
          ]),
          const SizedBox(height: 8),
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(review.comment!,
                style: TextStyle(color: Colors.grey[850], height: 1.5)),
        ],
      ),
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
}
