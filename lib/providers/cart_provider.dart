// file: lib/providers/cart_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/cart_model.dart';
import 'auth_provider.dart';

class CartProvider with ChangeNotifier {
  final AuthProvider authProvider;

  CartModel? _cart;
  CartModel? get cart => _cart;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final String _baseApiUrl = 'http://10.0.2.2:8080/api/users';

  CartProvider(this.authProvider) {
    if (authProvider.isAuthenticated && authProvider.user != null) {
      fetchCart();
    }
  }

  // Phương thức nội bộ để cập nhật trạng thái loading và thông báo cho UI
  void _setLoading(bool loading) {
    if (_isLoading == loading) return; // Tránh gọi không cần thiết
    _isLoading = loading;
    notifyListeners();
  }

  // Phương thức nội bộ để cập nhật thông báo lỗi và thông báo cho UI
  void _setErrorMessage(String? message) {
    _errorMessage = message;
    // Không gọi notifyListeners() ở đây ngay, hàm chính sẽ gọi
  }

  Future<void> fetchCart() async {
    if (authProvider.isGuest || authProvider.user == null) {
      _cart = CartModel(items: [], totalItems: 0, distinctItems: 0, cartTotalPrice: 0.0);
      notifyListeners();
      return;
    }
    // Giả sử User.id trong AuthProvider là int
    final int userId = authProvider.user!.id;

    _setLoading(true); // Báo hiệu bắt đầu tải
    _errorMessage = null; // Xóa lỗi cũ
    // notifyListeners(); // _setLoading đã gọi

    try {
      final url = Uri.parse('$_baseApiUrl/$userId/cart');
      print("CartProvider: Đang tải giỏ hàng từ: $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print("CartProvider: Phản hồi API giỏ hàng: $responseBody");
        final Map<String, dynamic> decodedData = jsonDecode(responseBody);
        _cart = CartModel.fromJson(decodedData);
      } else {
        final responseBody = utf8.decode(response.bodyBytes);
        print("CartProvider: Lỗi tải giỏ hàng (body): $responseBody");
        _setErrorMessage("Lỗi tải giỏ hàng: ${response.statusCode}");
        _cart = null;
      }
    } catch (e) {
      _setErrorMessage("Lỗi kết nối hoặc xử lý khi tải giỏ hàng: ${e.toString()}");
      _cart = null;
      print("CartProvider: Lỗi fetchCart: $e");
    } finally {
      _setLoading(false); // ✅ Luôn đặt lại isLoading và thông báo ở cuối
    }
  }

  // ✅ HÀM ĐÃ ĐƯỢC CẬP NHẬT
  Future<bool> addItemToCart(int productId, int quantity, {String? color, String? size}) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _setErrorMessage("Vui lòng đăng nhập để thêm sản phẩm vào giỏ.");
      notifyListeners();
      return false;
    }
    final int userId = authProvider.user!.id;

    _setLoading(true);
    _setErrorMessage(null);

    bool success = false;
    try {
      final url = Uri.parse('$_baseApiUrl/$userId/cart/items');

      // Tạo body cho request, bao gồm cả size và color
      final Map<String, dynamic> requestBody = {
        'productId': productId,
        'quantity': quantity,
        'color': color, // Có thể null
        'size': size,   // Có thể null
      };

      print("CartProvider: Thêm sản phẩm vào giỏ hàng: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody), // Gửi body đã có size và color
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Sau khi thêm thành công, tải lại toàn bộ giỏ hàng để đảm bảo dữ liệu đồng bộ
        await fetchCart();
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _setErrorMessage("Lỗi thêm vào giỏ hàng: ${responseData['message'] ?? response.reasonPhrase}");
        success = false;
      }
    } catch (e) {
      _setErrorMessage("Lỗi kết nối khi thêm vào giỏ hàng: ${e.toString()}");
      print("CartProvider: Lỗi addItemToCart: $e");
      success = false;
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> updateCartItemQuantity(int productId, int newQuantity) async {
    if (authProvider.isGuest || authProvider.user == null) { _setErrorMessage("Vui lòng đăng nhập."); notifyListeners(); return false; }
    final int userId = authProvider.user!.id;

    _setLoading(true);
    _setErrorMessage(null);
    // notifyListeners();

    bool success = false;
    try {
      final url = Uri.parse('$_baseApiUrl/$userId/cart/items/$productId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'quantity': newQuantity}),
      );
      if (response.statusCode == 200) {
        await fetchCart();
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _setErrorMessage("Lỗi cập nhật giỏ hàng: ${responseData['message'] ?? response.reasonPhrase}");
      }
    } catch (e) { _setErrorMessage("Lỗi kết nối: ${e.toString()}"); }
    finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> removeItemFromCart(int productId) async {
    if (authProvider.isGuest || authProvider.user == null) { _setErrorMessage("Vui lòng đăng nhập."); notifyListeners(); return false; }
    final int userId = authProvider.user!.id;
    _setLoading(true);
    _setErrorMessage(null);
    // notifyListeners();

    bool success = false;
    try {
      final url = Uri.parse('$_baseApiUrl/$userId/cart/items/$productId');
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchCart();
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _setErrorMessage("Lỗi xóa khỏi giỏ hàng: ${responseData['message'] ?? response.reasonPhrase}");
      }
    } catch (e) { _setErrorMessage("Lỗi kết nối: ${e.toString()}");}
    finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> clearCart() async {
    if (authProvider.isGuest || authProvider.user == null) { _setErrorMessage("Vui lòng đăng nhập."); notifyListeners(); return false; }
    final int userId = authProvider.user!.id;
    _setLoading(true);
    _setErrorMessage(null);
    // notifyListeners();

    bool success = false;
    try {
      final url = Uri.parse('$_baseApiUrl/$userId/cart');
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Thay vì fetchCart, chúng ta có thể reset _cart ở client luôn
        _cart = CartModel(items: [], totalItems: 0, distinctItems: 0, cartTotalPrice: 0.0);
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _setErrorMessage("Lỗi xóa giỏ hàng: ${responseData['message'] ?? response.reasonPhrase}");
      }
    } catch (e) { _setErrorMessage("Lỗi kết nối: ${e.toString()}");}
    finally {
      _setLoading(false);
    }
    return success;
  }

  void clearCartDataOnLogout() {
    _cart = CartModel(items: [], totalItems: 0, distinctItems: 0, cartTotalPrice: 0.0);
    _errorMessage = null;
    _isLoading = false; // Đảm bảo isLoading là false
    notifyListeners();
  }

  // Hàm này có thể không cần thiết nếu ChangeNotifierProxyProvider được cấu hình đúng
  // để tạo lại CartProvider khi AuthProvider thay đổi user,
  // hoặc nếu logic fetch/clear được gọi đúng trong update của ProxyProvider.
  void updateAuthProvider(AuthProvider newAuthProvider) {
    // authProvider = newAuthProvider; // Không thể gán lại final field
    // Cần logic để quyết định có fetch lại cart không dựa trên newAuthProvider.user.id
    // Ví dụ:
    // if (newAuthProvider.isAuthenticated && newAuthProvider.user != null) {
    //   if (_cart == null || (authProvider.user != null && authProvider.user!.id != newAuthProvider.user!.id)) {
    //     fetchCart(); // Fetch nếu user mới hoặc chưa có cart
    //   }
    // } else {
    //   clearCartDataOnLogout();
    // }
    // Tuy nhiên, việc này thường được xử lý tốt hơn trong update của ChangeNotifierProxyProvider.
    // Hiện tại, constructor và update của ProxyProvider đã gọi fetchCart/clearCartDataOnLogout.
  }

  @override
  void dispose() {
    // Không có controller nào được tạo trong CartProvider này để dispose
    super.dispose();
  }
}
