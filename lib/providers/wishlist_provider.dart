// file: lib/providers/wishlist_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/wishlist_item_model.dart'; // Model cho item trong wishlist
import 'auth_provider.dart'; // Để lấy thông tin user và trạng thái đăng nhập

class WishlistProvider with ChangeNotifier {
  // _authProvider nên được cập nhật bởi ChangeNotifierProxyProvider
  // khi AuthProvider thay đổi, thay vì gán lại trực tiếp ở đây.
  // Constructor sẽ nhận giá trị AuthProvider ban đầu.
  final AuthProvider authProvider;

  WishlistProvider(this.authProvider) {
    // Tải wishlist ban đầu nếu người dùng đã đăng nhập
    if (authProvider.isAuthenticated && authProvider.user != null) {
      fetchWishlist();
    }
  }

  List<WishlistItemModel> _wishlistItems = [];
  List<WishlistItemModel> get wishlistItems => _wishlistItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // isLoading cho các hành động cụ thể (add/remove) để có thể hiển thị
  // loading indicator riêng cho từng nút nếu muốn.
  bool _isAddingRemovingItem = false;
  bool get isAddingRemovingItem => _isAddingRemovingItem;
  int? _processingProductId; // ID của sản phẩm đang được thêm/xóa
  int? get processingProductId => _processingProductId;


  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // URL cơ sở cho API wishlist (trỏ đến /api/users của backend)
  final String _baseApiUrl = 'http://10.0.2.2:8080/api/users';

  // Hàm helper để lấy headers (nếu API yêu cầu token)
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    // final token = authProvider.token; // Giả sử AuthProvider có token
    // if (token != null) {
    //   headers['Authorization'] = 'Bearer $token';
    // }
    return headers;
  }

  // Hàm kiểm tra xem một sản phẩm có trong wishlist không
  bool isProductInWishlist(int productId) {
    if (authProvider.isGuest || authProvider.user == null) return false;
    return _wishlistItems.any((item) => item.productId == productId);
  }

  // Tải danh sách yêu thích từ backend
  Future<void> fetchWishlist() async {
    if (authProvider.isGuest || authProvider.user == null) {
      _wishlistItems = []; // Xóa wishlist nếu là guest hoặc user null
      _errorMessage = null; // Xóa lỗi cũ
      // Không cần notifyListeners() ở đây nếu hàm gọi nó sẽ notify,
      // hoặc nếu việc clearWishlistOnLogout đã notify rồi.
      // Tuy nhiên, để đảm bảo UI cập nhật khi fetch bị bỏ qua do guest, có thể gọi:
      // notifyListeners();
      return;
    }
    // Đảm bảo authProvider.user!.id là int để khớp với backend API
    final int userId = authProvider.user!.id;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseApiUrl/$userId/wishlist');
      print("WishlistProvider: Fetching wishlist from $url");

      final response = await http.get(url, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print("WishlistProvider: Wishlist API response: $responseBody");
        final decodedData = jsonDecode(responseBody);

        if (decodedData is List) {
          final List<WishlistItemModel?> tempList = decodedData
              .map((data) => WishlistItemModel.fromJson(data as Map<String, dynamic>))
              .toList();
          _wishlistItems = tempList.whereType<WishlistItemModel>().toList(); // Lọc bỏ các item null
          print("WishlistProvider: Parsed and filtered ${_wishlistItems.length} valid wishlist items.");
        } else if (decodedData is Map && decodedData.containsKey('message') &&
            (decodedData['items'] == null || (decodedData['items'] is List && (decodedData['items'] as List).isEmpty)) ) {
          // Xử lý trường hợp backend trả về CartResponseDTO với items rỗng và có message
          // (Mặc dù đây là Wishlist, cấu trúc response có thể tương tự nếu API /wishlist trả về dạng này)
          _wishlistItems = [];
          print("WishlistProvider: Wishlist is empty or response indicates empty: ${decodedData['message']}");
        } else {
          _wishlistItems = [];
          _errorMessage = "Dữ liệu wishlist không hợp lệ từ server.";
          print("WishlistProvider: Invalid wishlist data format from server.");
        }
      } else {
        _errorMessage = "Lỗi tải wishlist: ${response.statusCode} - ${response.body}";
        _wishlistItems = [];
        print("WishlistProvider: Error fetching wishlist - ${response.statusCode}");
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý khi tải wishlist: ${e.toString()}";
      _wishlistItems = [];
      print("WishlistProvider: Exception fetching wishlist: $e");
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
    final int userId = authProvider.user!.id;

    if (isProductInWishlist(productId)) {
      _errorMessage = "Sản phẩm đã có trong danh sách yêu thích.";
      notifyListeners();
      return false; // Không thêm lại, trả về false để UI biết
    }

    _isAddingRemovingItem = true;
    _processingProductId = productId; // Đánh dấu sản phẩm đang xử lý
    _errorMessage = null; // Xóa lỗi cũ
    notifyListeners();

    bool success = false;
    try {
      final url = Uri.parse('$_baseApiUrl/$userId/wishlist');
      print("WishlistProvider: Adding product ID $productId to wishlist for user ID $userId");
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({'productId': productId}),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      print("WishlistProvider: Add to wishlist response - Status: ${response.statusCode}, Body: $responseData");


      if (response.statusCode == 201 || response.statusCode == 200) { // 201 Created hoặc 200 OK (nếu API trả về item đã tồn tại)
        // API của bạn trả về Map {"message": "...", "wishlistItemId": ID}
        // hoặc WishlistItem mới.
        // Chúng ta sẽ fetch lại toàn bộ wishlist để đảm bảo dữ liệu đồng bộ và có wishlistItemId đúng.
        await fetchWishlist();
        success = true;
      } else {
        _errorMessage = responseData['message'] as String? ?? "Lỗi thêm vào wishlist.";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi thêm vào wishlist: ${e.toString()}";
      print("WishlistProvider: Exception adding to wishlist: $e");
    }

    _isAddingRemovingItem = false;
    _processingProductId = null;
    notifyListeners();
    return success;
  }

  // Xóa sản phẩm khỏi wishlist
  Future<bool> removeFromWishlist(int productId, {int? wishlistItemIdToDelete}) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để xóa sản phẩm.";
      notifyListeners();
      return false;
    }
    final int userId = authProvider.user!.id;

    _isAddingRemovingItem = true;
    _processingProductId = productId;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      // API: DELETE /api/users/{userId}/wishlist/{productId}
      final url = Uri.parse('$_baseApiUrl/$userId/wishlist/$productId');
      print("WishlistProvider: Removing product ID $productId from wishlist for user ID $userId");

      final response = await http.delete(url, headers: await _getAuthHeaders());
      print("WishlistProvider: Remove from wishlist response - Status: ${response.statusCode}");


      if (response.statusCode == 200 || response.statusCode == 204) { // 204 No Content
        _wishlistItems.removeWhere((item) => item.productId == productId); // Xóa ở client trước
        // await fetchWishlist(); // Có thể không cần fetch lại nếu UI đã cập nhật
        success = true;
      } else {
        try {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          _errorMessage = responseData['message'] as String? ?? "Lỗi xóa khỏi wishlist.";
        } catch (e) {
          _errorMessage = "Lỗi xóa khỏi wishlist: ${response.statusCode}";
        }
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi xóa khỏi wishlist: ${e.toString()}";
      print("WishlistProvider: Exception removing from wishlist: $e");
    }

    _isAddingRemovingItem = false;
    _processingProductId = null;
    notifyListeners();
    return success;
  }

  // Dọn dẹp dữ liệu wishlist khi người dùng đăng xuất
  void clearWishlistOnLogout() {
    _wishlistItems = [];
    _errorMessage = null;
    _isLoading = false;
    _isAddingRemovingItem = false;
    _processingProductId = null;
    notifyListeners();
    print("WishlistProvider: Cleared wishlist data due to logout or auth change.");
  }

  // Hàm này được gọi bởi ChangeNotifierProxyProvider trong main.dart
  // để WishlistProvider có thể phản ứng với thay đổi của AuthProvider.
  void updateAuthProvider(AuthProvider newAuth) {
    // Không gán lại this.authProvider vì nó là final và được inject qua constructor.
    // Logic chính để phản ứng với thay đổi auth được xử lý bởi ProxyProvider trong main.dart,
    // nó sẽ gọi fetchWishlist() hoặc clearWishlistOnLogout() trên instance WishlistProvider hiện tại.
    // Hàm này ở đây chỉ mang tính thông báo hoặc nếu bạn có logic phức tạp hơn cần
    // truy cập trực tiếp vào newAuth mà không muốn chờ ProxyProvider tạo lại instance.

    // Ví dụ: Nếu user thay đổi từ guest -> loggedIn, hoặc loggedIn -> guest
    bool wasAuthenticated = authProvider.isAuthenticated;
    bool isAuthenticatedNow = newAuth.isAuthenticated;

    if (wasAuthenticated != isAuthenticatedNow) {
      if (isAuthenticatedNow && newAuth.user != null) {
        print("WishlistProvider's updateAuthProvider: User is now authenticated. Fetching wishlist.");
        fetchWishlist();
      } else {
        print("WishlistProvider's updateAuthProvider: User is now unauthenticated. Clearing wishlist.");
        clearWishlistOnLogout();
      }
    } else if (isAuthenticatedNow && newAuth.user != null && authProvider.user?.id != newAuth.user?.id) {
      // User thay đổi (ví dụ: chuyển tài khoản mà không logout hẳn)
      print("WishlistProvider's updateAuthProvider: User changed. Fetching wishlist for new user.");
      fetchWishlist();
    }
    // Quan trọng: Gán lại authProvider để các hàm khác trong provider này sử dụng đúng instance mới
    // Tuy nhiên, với ChangeNotifierProxyProvider, thường thì một instance mới của WishlistProvider
    // sẽ được tạo với AuthProvider mới, hoặc ProxyProvider sẽ đảm bảo WishlistProvider hiện tại
    // nhận được AuthProvider cập nhật.
    // Nếu bạn muốn cập nhật authProvider nội bộ của instance này:
    // this.authProvider = newAuth; // Điều này sẽ yêu cầu authProvider không phải là final.
    // Hiện tại, chúng ta dựa vào việc constructor nhận AuthProvider đúng.
  }
  Future<bool> toggleWishlistItem(int productId) async {
    if (isProductInWishlist(productId)) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(productId);
    }
  }

}