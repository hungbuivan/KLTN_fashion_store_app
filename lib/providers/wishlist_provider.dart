// file: lib/providers/wishlist_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/wishlist_item_model.dart'; // Import model wishlist
import 'auth_provider.dart'; // Import AuthProvider để lấy userId

class WishlistProvider with ChangeNotifier {
  final AuthProvider authProvider;

  WishlistProvider(this.authProvider) {
    // Tự động tải wishlist khi provider được tạo và người dùng đã đăng nhập
    // Kiểm tra kỹ authProvider.user không null trước khi truy cập id
    if (authProvider.isAuthenticated && authProvider.user != null) {
      fetchWishlist();
    }
  }

  List<WishlistItemModel> _wishlistItems = [];
  List<WishlistItemModel> get wishlistItems => _wishlistItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // URL cơ sở cho API wishlist (thay đổi IP nếu cần)
  final String _baseApiUrl = 'http://10.0.2.2:8080/api/users';


  // Hàm kiểm tra xem một sản phẩm có trong wishlist không
  bool isProductInWishlist(int productId) {
    return _wishlistItems.any((item) => item.productId == productId);
  }

  // Tải danh sách yêu thích
  Future<void> fetchWishlist() async {
    if (authProvider.isGuest || authProvider.user == null) {
      _wishlistItems = [];
      notifyListeners();
      return;
    }
    // ✅ authProvider.user!.id đã là int (từ User model)
    // Backend WishlistController mong đợi Integer userId.
    final int userId = authProvider.user!.id;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseApiUrl/$userId/wishlist');
      print("WishlistProvider: Đang tải wishlist từ: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print("WishlistProvider: Phản hồi API wishlist: $responseBody");
        final decodedData = jsonDecode(responseBody);

        if (decodedData is List) {
          final List<dynamic> itemsData = decodedData;
          final List<WishlistItemModel?> tempList = itemsData
              .map((data) => WishlistItemModel.fromJson(data as Map<String, dynamic>))
              .toList();
          _wishlistItems = tempList.whereType<WishlistItemModel>().toList(); // Lọc bỏ null
          print("WishlistProvider: Đã parse và lọc được ${_wishlistItems.length} wishlist items hợp lệ.");
        } else if (decodedData is Map && decodedData.containsKey('message')) {
          _wishlistItems = [];
          print("WishlistProvider: ${decodedData['message']}");
        } else {
          _wishlistItems = [];
          _errorMessage = "Dữ liệu wishlist không hợp lệ từ server.";
        }
      } else {
        _errorMessage = "Lỗi tải wishlist: ${response.statusCode} - ${response.body}";
        _wishlistItems = [];
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý khi tải wishlist: ${e.toString()}";
      _wishlistItems = [];
      print("WishlistProvider: Lỗi fetchWishlist: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Thêm sản phẩm vào wishlist
  Future<bool> addToWishlist(int productId) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để thêm vào yêu thích.";
      notifyListeners();
      return false;
    }
    // ✅ authProvider.user!.id đã là int
    final int userId = authProvider.user!.id;

    if (isProductInWishlist(productId)) {
      print("WishlistProvider: Sản phẩm ID $productId đã có trong wishlist.");
      // Cân nhắc: có thể vẫn gọi API để đồng bộ với server nếu client state bị lệch,
      // hoặc chỉ trả về true nếu không muốn gọi API thừa.
      // Hiện tại, nếu đã có ở client thì coi như thành công.
      return true;
    }

    _isLoading = true; // Chỉ nên set loading cho hành động cụ thể này nếu cần thiết
    notifyListeners();
    bool success = false;

    try {
      final url = Uri.parse('$_baseApiUrl/$userId/wishlist');
      print("WishlistProvider: Thêm sản phẩm ID $productId vào wishlist cho user ID $userId");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'productId': productId}), // productId đã là int, jsonEncode sẽ xử lý
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchWishlist(); // Tải lại toàn bộ wishlist để đảm bảo đồng bộ
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = "Lỗi thêm vào wishlist: ${responseData['message'] ?? response.reasonPhrase}";
        // success vẫn là false
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi thêm vào wishlist: ${e.toString()}";
      print("WishlistProvider: Lỗi addToWishlist: $e");
      // success vẫn là false
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // Xóa sản phẩm khỏi wishlist
  Future<bool> removeFromWishlist(int productId, {int? wishlistItemIdToDelete}) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để xóa khỏi yêu thích.";
      notifyListeners();
      return false;
    }
    // ✅ authProvider.user!.id đã là int
    final int userId = authProvider.user!.id;

    _isLoading = true; // Chỉ nên set loading cho hành động cụ thể này nếu cần thiết
    notifyListeners();
    bool success = false;

    try {
      // Backend API của bạn là DELETE /api/users/{userId}/wishlist/{productId}
      final url = Uri.parse('$_baseApiUrl/$userId/wishlist/$productId');
      print("WishlistProvider: Xóa sản phẩm ID $productId khỏi wishlist của user ID $userId");

      final response = await http.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content cũng là thành công
        await fetchWishlist(); // Tải lại wishlist
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = "Lỗi xóa khỏi wishlist: ${responseData['message'] ?? response.reasonPhrase}";
        // success vẫn là false
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi xóa khỏi wishlist: ${e.toString()}";
      print("WishlistProvider: Lỗi removeFromWishlist: $e");
      // success vẫn là false
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void clearWishlistOnLogout() {
    _wishlistItems = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
