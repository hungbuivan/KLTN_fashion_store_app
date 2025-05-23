// category_page.dart
import 'package:flutter/material.dart';

import '../widgets/all_product.dart';

// Giả sử bạn có một model cho Category
class Category {
  final String name;
  final String imageUrl; // Đường dẫn ảnh hoặc URL
  // Thêm các thuộc tính khác nếu cần

  Category({required this.name, required this.imageUrl});
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with SingleTickerProviderStateMixin { // Thêm SingleTickerProviderStateMixin nếu dùng TabController
  // Dữ liệu mẫu cho danh mục (sau này sẽ lấy từ API hoặc database)
  final List<Category> _categories = [
    Category(name: "Men", imageUrl: "assets/images/clothing.png"), // Thay bằng đường dẫn ảnh thực tế
    Category(name: "Shoes", imageUrl: "assets/images/shoes.png"),
    Category(name: "Women", imageUrl: "assets/images/accessories.png"),
    Category(name: "Couple", imageUrl: "assets/images/accessories.png"),
    Category(name: "Bag", imageUrl: "assets/images/accessories.png"),
    // Thêm các danh mục khác
  ];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 tabs: Products, Categories
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView( // Sử dụng NestedScrollView để thanh tab có thể cuộn cùng nội dung hoặc cố định
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
                backgroundColor: Colors.white, // Hoặc màu nền bạn muốn
                pinned: false, // Tiêu đề "Explore" không pin lại khi cuộn
                automaticallyImplyLeading: false, // Bỏ nút back nếu không cần
                elevation: 0,
              ),
              SliverToBoxAdapter( // Cho thanh tìm kiếm
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader( // Cho TabBar
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue, // Màu chữ của tab được chọn
                    unselectedLabelColor: Colors.grey, // Màu chữ của tab không được chọn
                    indicatorColor: Colors.blue, // Màu của gạch chân dưới tab được chọn
                    tabs: const [
                      Tab(text: 'Products'),
                      Tab(text: 'Categories'),

                    ],
                  ),
                ),
                pinned: true, // Pin TabBar lại khi cuộn
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: <Widget>[
              // Nội dung cho tab "Products"
              AllProducts(), // <-- THAY THẾ Ở ĐÂY

              // Nội dung cho tab "Categories" (Lưới danh mục)
              _buildCategoriesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        // physics: NeverScrollableScrollPhysics(), // Bỏ dòng này nếu GridView là nội dung chính của TabBarView và cần cuộn độc lập
        // shrinkWrap: true, // Bỏ dòng này nếu GridView là nội dung chính của TabBarView
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Số cột
          crossAxisSpacing: 16.0, // Khoảng cách ngang giữa các item
          mainAxisSpacing: 16.0, // Khoảng cách dọc giữa các item
          childAspectRatio: 0.85, // Tỷ lệ chiều rộng/chiều cao của mỗi item (điều chỉnh cho phù hợp)
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryItem(category);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Category category) {
    return GestureDetector(
      onTap: () {
        // Xử lý khi người dùng nhấn vào một danh mục
        print('Tapped on ${category.name}');
        // Ví dụ: Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsByCategoryPage(category: category)));
      },
      child: Card(
        clipBehavior: Clip.antiAlias, // Để bo góc hình ảnh
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Image.asset( // Hoặc Image.network nếu URL từ API
                category.imageUrl,
                fit: BoxFit.cover,
                // Thêm errorBuilder cho Image nếu cần
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Delegate cho SliverPersistentHeader để giữ TabBar cố định
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Màu nền cho khu vực TabBar
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}