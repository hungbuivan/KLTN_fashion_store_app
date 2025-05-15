import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Đảm bảo đường dẫn này ĐÚNG tới file model PopularItem của bạn
// Nếu PopularItem.dart nằm trong thư mục con của widgets, ví dụ: widgets/models/popular_item.dart
// thì import '../widgets/models/popular_item.dart';
// Hoặc nếu nó ở cùng cấp với all_product.dart trong một thư mục screens chẳng hạn:
// import '../models/popular_item.dart'; // Giả sử models là thư mục ngang cấp với screens
import '../models/popular_item.dart';
import 'navigation_menu.dart'; // Giữ nguyên nếu đường dẫn này đúng

class AllProducts extends StatefulWidget {
  const AllProducts({super.key});

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  List<PopularItem> _allItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllItems();
  }

  Future<void> _fetchAllItems() async {
    // URL API để lấy tất cả sản phẩm
    final url = Uri.parse('http://10.0.2.2:8080/api/products'); // Đảm bảo endpoint này đúng
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _allItems = jsonData.map((itemJson) => PopularItem.fromJson(itemJson)).toList();
          _isLoading = false;
          _errorMessage = null; // Xóa lỗi nếu thành công
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load products. Status code: ${response.statusCode} from ${url.toString()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching products: $e from ${url.toString()}';
        _isLoading = false;
      });
    }
  }
  // --- SỬA HÀM NÀY ĐỂ ĐỔI "localhost:8080" THÀNH "10.0.2.2:8080" ---
  String fixImageUrl(String? originalUrlFromApi) {
    // Kiểm tra nếu originalUrlFromApi là null hoặc rỗng
    if (originalUrlFromApi == null || originalUrlFromApi.isEmpty) {
      print("fixImageUrl: Received null or empty URL, returning empty.");
      return ''; // Trả về chuỗi rỗng hoặc một URL placeholder mặc định
    }

    String correctedUrl = originalUrlFromApi;

    // Bước 1: Thay thế "localhost:8080" bằng "10.0.2.2:8080" nếu có
    if (correctedUrl.contains('://localhost:8080')) {
      print("fixImageUrl: Found 'localhost:8080' in $correctedUrl. Replacing...");
      correctedUrl = correctedUrl.replaceFirst('://localhost:8080', '://10.0.2.2:8080');
      print("fixImageUrl: Corrected URL is now $correctedUrl");
    }

    // Bước 2: (Fallback) Nếu URL sau khi sửa (hoặc URL gốc) vẫn không bắt đầu bằng "http"
    // (ví dụ: backend chỉ trả về tên file như "nike_tshirt.jpg")
    // thì mới ghép với base URL đầy đủ.
    // Nếu backend đã trả về URL đầy đủ (dù là localhost hay 10.0.2.2),
    // thì bước này sẽ không cần thiết sau khi bước 1 đã chạy.
    if (!correctedUrl.toLowerCase().startsWith('http')) {
      print("fixImageUrl: URL '$correctedUrl' does not start with http. Prepending base path...");
      // Giả định ảnh sản phẩm nằm trong images/products/
      correctedUrl = 'http://10.0.2.2:8080/images/products/$correctedUrl';
      print("fixImageUrl: Final URL for filename is $correctedUrl");
    }

    return correctedUrl;
  }
  // --- KẾT THÚC SỬA HÀM ---


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red), textAlign: TextAlign.center,));
    }
    if (_allItems.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "All product",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NavigationMenu(selectedIndex: 1), // Mở Categories
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // Thêm padding vertical
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65, // Điều chỉnh tỉ lệ này nếu cần để vừa vặn hơn
              ),
              itemCount: _allItems.length,
              itemBuilder: (context, index) {
                return _buildItemCard(_allItems[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(PopularItem item) {
    // --- CÁC LỆNH PRINT ĐỂ DEBUG ---
    print('AllProducts - Rendering item: ${item.name}');
    print('AllProducts - Raw imageUrl from API: ${item.imageUrl}');

    // Xử lý imageUrl, truyền chuỗi rỗng nếu item.imageUrl là null để tránh lỗi
    final String finalImageUrl = fixImageUrl(item.imageUrl ?? '');
    print('AllProducts - Final imageUrl for Image.network: $finalImageUrl');
    // --- KẾT THÚC PHẦN DEBUG ---

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Giảm bo góc một chút
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch để ClipRRect chiếm full width
        children: [
          // Ảnh sản phẩm
          Expanded( // Cho phép ảnh chiếm không gian linh hoạt
            flex: 3, // Ảnh chiếm nhiều không gian hơn
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: finalImageUrl.isEmpty // Kiểm tra nếu URL rỗng thì hiển thị placeholder
                  ? Container(
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
              )
                  : Image.network(
                finalImageUrl,
                fit: BoxFit.cover,
                // --- THÊM LOADINGBUILDER VÀ ERRORBUILDER ---
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                  print('AllProducts - Error loading image $finalImageUrl: $error');
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                  );
                },
              ),
            ),
          ),
          // Tên, giá, nút
          Expanded( // Phần thông tin chiếm không gian còn lại
            flex: 2, // Thông tin chiếm ít không gian hơn ảnh
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0, bottom: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều không gian
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? 'No Name', // Xử lý null cho tên
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2, // Cho phép 2 dòng
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    // ignore: unnecessary_null_comparison
                    item.price != null ? "\$${item.price.toStringAsFixed(2)}" : "N/A", // Xử lý null cho giá
                    style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                  ),
                  SizedBox( // Bọc ElevatedButton trong SizedBox để kiểm soát kích thước tốt hơn nếu cần
                    width: double.infinity, // Cho nút chiếm hết chiều rộng
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Add to cart ${item.name}');
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Giảm vùng chạm
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}