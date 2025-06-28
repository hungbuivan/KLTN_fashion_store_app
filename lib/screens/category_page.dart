// file: lib/screens/category_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Import các provider và model cần thiết
import '../providers/category_provider.dart';
import '../models/category_node_model.dart';

// Import các widget và màn hình khác
import '../widgets/all_product.dart';
import 'products_by_category_screen.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với 2 tab: "Sản phẩm" và "Danh mục"
    _tabController = TabController(length: 2, vsync: this);

    // Tùy chọn: Gọi lại fetchCategoryTree nếu bạn muốn đảm bảo dữ liệu luôn mới nhất khi vào trang
    // Việc này đã được thực hiện trong constructor của CategoryProvider, nhưng gọi lại ở đây
    // sẽ hữu ích nếu bạn muốn có chức năng "kéo để làm mới" trong tương lai.
    // Provider.of<CategoryProvider>(context, listen: false).fetchCategoryTree();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                title: const Text('Danh mục', style: TextStyle(fontSize: 25, color: Colors.black)),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                pinned: false,
                automaticallyImplyLeading: false,
                elevation: 0,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm',
                      prefixIcon: const Icon(Icons.search),
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
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Sản phẩm'),
                      Tab(text: 'Danh mục'), // Hoặc Danh mục cha
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: <Widget>[
              // ✅ Bọc lại bằng SingleChildScrollView
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: AllProducts(), // AllProducts sẽ không có scroll riêng, chỉ hiển thị nội dung
              ),

              // Nội dung cho tab "Danh mục"
              Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  // Hiển thị vòng xoay loading khi đang tải
                  if (categoryProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Hiển thị lỗi nếu có
                  if (categoryProvider.errorMessage != null) {
                    return Center(child: Text(categoryProvider.errorMessage!));
                  }
                  // Hiển thị danh sách rỗng
                  if (categoryProvider.categoryTree.isEmpty) {
                    return const Center(child: Text('Không có danh mục nào.'));
                  }
                  // Hiển thị cây danh mục
                  return _buildCategoryTree(categoryProvider.categoryTree);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget để xây dựng giao diện cây danh mục
  Widget _buildCategoryTree(List<CategoryNodeModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final parentCategory = categories[index];

        // Nếu danh mục cha không có con, nó sẽ hoạt động như một nút ListTile bình thường
        if (parentCategory.children.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Iconsax.category),
              title: Text(parentCategory.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(Iconsax.arrow_right_3, size: 18),
              onTap: () {
                // Điều hướng khi nhấn vào danh mục cha không có con
                Navigator.of(context).pushNamed(
                  ProductsByCategoryScreen.routeName,
                  arguments: {
                    'categoryId': parentCategory.id,
                    'categoryName': parentCategory.name,
                  },
                );
              },
            ),
          );
        }

        // Ngược lại, nếu có con, hiển thị dạng ExpansionTile có thể mở rộng
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: PageStorageKey(parentCategory.id), // Giữ trạng thái đóng/mở khi cuộn
            leading: const Icon(Iconsax.folder_open),
            title: Text(
              parentCategory.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            children: parentCategory.children.map((childCategory) {
              return _buildSubCategoryItem(childCategory);
            }).toList(),
          ),
        );
      },
    );
  }

  // Widget để xây dựng giao diện cho mỗi danh mục con
  Widget _buildSubCategoryItem(CategoryNodeModel subCategory) {
    return Material(
      color: Colors.grey.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 30.0, right: 16.0),
        leading: const Icon(Iconsax.category_2, size: 20),
        title: Text(subCategory.name),
        trailing: const Icon(Iconsax.arrow_right_3, size: 18),
        onTap: () {
          // Điều hướng khi nhấn vào một danh mục con
          Navigator.of(context).pushNamed(
            ProductsByCategoryScreen.routeName,
            arguments: {
              'categoryId': subCategory.id,
              'categoryName': subCategory.name,
            },
          );
        },
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
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return Container(
      color: Theme
          .of(context)
          .scaffoldBackgroundColor, // Đồng bộ màu nền
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}