// file: lib/providers/order_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import các model liên quan đến Order
import '../models/order_detail_model.dart';
import '../models/order_summary_model.dart';
// import '../models/cart_item_model.dart'; // Chỉ cần nếu CartItemInfoData không được định nghĩa bên dưới
import '../models/page_response_model.dart';
import '../models/shipping_address_model.dart';

// Import các provider khác
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'voucher_provider.dart';

// DTO (Data Transfer Object) cho việc tạo đơn hàng ở Flutter,
// tương ứng với OrderCreateRequest.java ở backend
class OrderCreateRequestData {
   //final int userId; // Backend sẽ tự lấy từ Principal/Token nếu có Spring Security
  final List<CartItemInfoData> cartItems;
  final ShippingAddressModel shippingAddress;
  final String paymentMethod;
  final double? shippingFee;
  final String? voucherCode;

  OrderCreateRequestData({
   // required this.userId,
    required this.cartItems,
    required this.shippingAddress,
    required this.paymentMethod,
    this.shippingFee,
    this.voucherCode,
  });

  Map<String, dynamic> toJson() {
    return {
      //if (userId != null) 'userId': userId, // Bỏ qua nếu backend tự lấy
      'cartItems': cartItems.map((item) => item.toJson()).toList(),
      'shippingAddress': shippingAddress.toJson(), // Giả sử ShippingAddressModel có toJson()
      'paymentMethod': paymentMethod,
      if (shippingFee != null) 'shippingFee': shippingFee,
      if (voucherCode != null && voucherCode!.isNotEmpty) 'voucherCode': voucherCode,
    };
  }
}

// DTO con cho cartItems trong OrderCreateRequestData
// Khớp với OrderCreateRequest.CartItemDTO ở backend
class CartItemInfoData {
  final int productId;
  final int quantity;
  final String? size;
  final String? color;

  CartItemInfoData({
    required this.productId,
    required this.quantity,
    this.size,
    this.color,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    if (size != null) 'size': size,
    if (color != null) 'color': color,
  };
}



class OrderProvider with ChangeNotifier {
  AuthProvider authProvider;
  final CartProvider cartProvider;
  final VoucherProvider voucherProvider;

  // Base URL cho API (thay đổi IP nếu cần)
  final String _baseUserSpecificOrderUrl = 'http://10.0.2.2:8080/api/users'; // Cho /users/{userId}/orders
  final String _baseGeneralOrderUrl = 'http://10.0.2.2:8080/api/orders';  // Cho /orders và /orders/{orderId}/...
  final String _baseAdminOrderUrl = 'http://10.0.2.2:8080/api/admin/orders';

  List<OrderSummaryModel> _userOrders = [];
  List<OrderSummaryModel> get userOrders => _userOrders;

  OrderDetailModel? _currentOrderDetail;
  OrderDetailModel? get currentOrderDetail => _currentOrderDetail;

  //phân trang
  int _currentPage = 0;
  bool _hasNextPage = true;

  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;


  // ✅ CẬP NHẬT CONSTRUCTOR
  OrderProvider({required this.authProvider, required this.cartProvider, required this.voucherProvider});
  // ✅ HÀM MỚI: Thêm lại các sản phẩm từ một đơn hàng cũ vào giỏ hàng
  Future repurchaseOrder(int orderId) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để thực hiện chức năng này.";
      return false;
    }
    // Có thể thêm một biến loading riêng nếu muốn
// _isLoadingRepurchase = true;
// notifyListeners();

    _clearError();

    try {
      final url = Uri.parse('$_baseGeneralOrderUrl/$orderId/buy-again');
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(), // Giả sử hàm này thêm token xác thực
      );

      if (response.statusCode == 200) {
        // Thêm vào giỏ hàng thành công ở backend.
        // Bây giờ, hãy làm mới giỏ hàng ở client để cập nhật UI.
        await cartProvider.fetchCart();

        return true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] ?? "Lỗi khi mua lại đơn hàng.";
        return false;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối: ${e.toString()}";
      return false;
    } finally {
      // _isLoadingRepurchase = false;
      // notifyListeners();
    }

  }


  // Lấy chi tiết một đơn hàng cho Admin
  Future<OrderDetailModel?> fetchOrderDetailForAdmin(int orderId) async {
    if (authProvider.isGuest || authProvider.user?.role != 'admin') {
      _errorMessage = "Không có quyền truy cập.";
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _clearError();
    _currentOrderDetail = null; // Xóa chi tiết cũ
    OrderDetailModel? fetchedOrder;

    try {
      // API: GET /api/admin/orders/{orderId}
      final url = Uri.parse('$_baseAdminOrderUrl/$orderId');
      print("OrderProvider (Admin): Fetching order detail from $url");

      final response = await http.get(url, headers: await _getAuthHeaders());
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        fetchedOrder = OrderDetailModel.fromJson(responseData as Map<String, dynamic>);
        _currentOrderDetail = fetchedOrder;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] as String? ?? "Lỗi tải chi tiết đơn hàng (Admin): ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi lấy chi tiết đơn hàng (Admin).";
      print("OrderProvider (Admin): Error fetching order detail: $e");
    }
    _setLoading(false);
    return fetchedOrder;
  }

  // ✅ PHẦN THÊM MỚI: State cho Admin
  List<OrderSummaryModel> _allAdminOrders = [];
  List<OrderSummaryModel> get allAdminOrders => _allAdminOrders;
  PageResponse<OrderSummaryModel>? _adminOrdersPageData;
  PageResponse<OrderSummaryModel>? get adminOrdersPageData => _adminOrdersPageData;
  // --- KẾT THÚC PHẦN THÊM MỚI ---

  bool _isLoading = false; // Loading chung cho các thao tác chính
  bool get isLoading => _isLoading;

  bool _isUpdatingStatus = false; // Loading riêng cho việc cập nhật trạng thái
  bool get isUpdatingStatus => _isUpdatingStatus;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // OrderProvider({
  //   required this.authProvider,
  //   required this.cartProvider,
  //   required this.voucherProvider,
  // }) {
  //   // Tự động tải lịch sử đơn hàng của user nếu đã đăng nhập khi provider được tạo
  //   // if (authProvider.isAuthenticated && authProvider.user != null) {
  //   //   fetchUserOrders();
  //   // }
  // }

  // ✅ SỬA LỖI Ở ĐÂY: đổi tên tham số thành isStatusUpdate
  void _setLoading(bool loading, {bool isStatusUpdate = false}) {
    if (isStatusUpdate) {
      if (_isUpdatingStatus == loading) return;
      _isUpdatingStatus = loading;
    } else {
      if (_isLoading == loading) return;
      _isLoading = loading;
    }
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // notifyListeners(); // Sẽ được gọi bởi hàm chính
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    // final token = authProvider.token; // Nếu bạn dùng token
    // if (token != null) {
    //   headers['Authorization'] = 'Bearer $token';
    // }
    return headers;
  }

  // === CÁC HÀM CHO USER ===

  // Tạo đơn hàng mới
  Future<OrderDetailModel?> createOrder({ // Sửa lại tham số để nhận các thành phần
    required List<CartItemInfoData> cartItems,
    required ShippingAddressModel shippingAddress,
    required String paymentMethod,
    required double shippingFee,
    String? voucherCode,
    required String initialStatus,
  }) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập để đặt hàng.";
      notifyListeners();
      return null;
    }
    final int loggedInUserId = authProvider.user!.id; // Lấy userId từ AuthProvider

    _setLoading(true);
    _clearError();
    OrderDetailModel? createdOrder;

    // Tạo OrderCreateRequest không có userId
    final OrderCreateRequestData orderPayload = OrderCreateRequestData(
        cartItems: cartItems,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        shippingFee: shippingFee,
        voucherCode: voucherCode
    );

    try {
      // API của bạn là POST /api/orders
      // OrderController.createOrder(OrderCreateRequest dto) sẽ nhận payload này.
      // Và OrderService.createOrder(OrderCreateRequest request, Integer loggedInUserId)
      // sẽ nhận loggedInUserId từ Controller (Controller lấy từ token/principal).
      //
      // LỖI Ở ĐÂY LÀ: OrderController hiện tại đang lấy userId TỪ OrderCreateRequest.
      // Chúng ta cần thống nhất.
      //
      // CÁCH 1: Backend Controller lấy userId từ Principal/Token (KHUYẾN NGHỊ)
      //    - Flutter OrderCreateRequestData KHÔNG cần userId.
      //    - Backend OrderController lấy userId từ @AuthenticationPrincipal.
      //    - Backend OrderService nhận loggedInUserId từ Controller.
      //
      // CÁCH 2: Client (Flutter) gửi userId trong OrderCreateRequestData (Như bạn đang gặp lỗi)
      //    - Flutter OrderCreateRequestData CÓ userId.
      //    - Backend OrderCreateRequest.java CÓ userId và @NotNull.
      //    - Backend OrderController dùng orderCreateRequest.getUserId().
      //    - Backend OrderService có thể nhận userId từ request DTO hoặc là tham số riêng.

      // Hiện tại, để FIX LỖI THEO CẤU TRÚC ĐANG CÓ (Cách 2),
      // chúng ta cần đảm bảo OrderCreateRequestData (Flutter) có userId
      // và OrderCreateRequest.java (Backend) có userId.
      //
      // Dựa trên lỗi bạn báo: "Field 'userId': rejected value [null]; ... default message [User ID không được để trống]"
      // => Backend OrderCreateRequest.java đang YÊU CẦU có userId.
      // => Flutter OrderCreateRequestData PHẢI gửi userId.

      // TẠO LẠI OrderCreateRequestData VỚI userId
      final Map<String, dynamic> finalPayloadJson = {
        'userId': loggedInUserId, // Thêm userId vào JSON gửi đi
        'cartItems': orderPayload.cartItems.map((item) => item.toJson()).toList(),
        'shippingAddress': orderPayload.shippingAddress.toJson(),
        'paymentMethod': orderPayload.paymentMethod,
        'status': initialStatus, // Gửi trạng thái ban đầu lên backend
        if (orderPayload.shippingFee != null) 'shippingFee': orderPayload.shippingFee,
        if (orderPayload.voucherCode != null && orderPayload.voucherCode!.isNotEmpty) 'voucherCode': orderPayload.voucherCode,
      };

      final url = Uri.parse(_baseGeneralOrderUrl);
      print("OrderProvider: Creating order to $url with data: ${jsonEncode(finalPayloadJson)}");

      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(finalPayloadJson), // Gửi JSON đã có userId
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      print("OrderProvider: Create order response - Status: ${response.statusCode}, Body: $responseData");

      if (response.statusCode == 201) { // 201 Created
        // Backend trả về OrderDetailDTO
        createdOrder = OrderDetailModel.fromJson(responseData as Map<String, dynamic>);

        // await cartProvider.clearCart(); // Xóa giỏ hàng ở client và có thể gọi API backend
        // voucherProvider.removeAppliedVoucher(); // Reset voucher đã áp dụng ở client

        await fetchUserOrders(); // Tải lại lịch sử đơn hàng của user
        _currentOrderDetail = createdOrder; // Lưu chi tiết đơn vừa tạo (tùy chọn)
        _errorMessage = null;
      } else {
        _errorMessage = responseData['message'] as String? ?? "Lỗi tạo đơn hàng: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối hoặc xử lý khi tạo đơn hàng: ${e.toString()}";
      print("OrderProvider: Error creating order: $e");
    } finally {
      _setLoading(false);
    }
    return createdOrder;
  }

  // Lấy lịch sử đơn hàng của người dùng hiện tại
  Future<void> fetchUserOrders({
    int page = 0,
    int size = 10,
    String sort = "createdAt,desc",
    bool isRefresh = false,
  }) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _userOrders = [];
      notifyListeners();
      return;
    }

    final int userId = authProvider.user!.id;
    if (page == 0) _setLoading(true); // Chỉ show loading nếu là trang đầu
    _clearError();

    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };

      final url = Uri.parse('$_baseUserSpecificOrderUrl/$userId/orders')
          .replace(queryParameters: queryParams);
      print("OrderProvider: Fetching user orders from $url");

      final response = await http.get(url, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final decodedData = jsonDecode(responseBody);

        if (decodedData is Map &&
            decodedData.containsKey('content') &&
            decodedData['content'] is List) {
          final List<dynamic> ordersData = decodedData['content'];
          final List<OrderSummaryModel?> tempList = ordersData
              .map((data) =>
              OrderSummaryModel.fromJson(data as Map<String, dynamic>))
              .toList();

          final List<OrderSummaryModel> newOrders =
          tempList.whereType<OrderSummaryModel>().toList();

          if (isRefresh || page == 0) {
            _userOrders = newOrders;
          } else {
            _userOrders.addAll(newOrders);
          }

          // ✅ Cập nhật phân trang
          _currentPage = decodedData['number'] ?? page;

          // ✅ Sửa chỗ lỗi: kiểm tra trường 'last' là bool
          if (decodedData.containsKey('last') && decodedData['last'] is bool) {
            _hasNextPage = !(decodedData['last'] as bool);
          } else {
            _hasNextPage = false; // fallback an toàn
          }
        } else {
          _errorMessage = "Dữ liệu đơn hàng không hợp lệ.";
          if (isRefresh || page == 0) _userOrders = [];
        }
      } else {
        _errorMessage =
        "Lỗi tải lịch sử đơn hàng: ${response.statusCode} - ${response.body}";
        if (isRefresh || page == 0) _userOrders = [];
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tải đơn hàng: ${e.toString()}";
      if (isRefresh || page == 0) _userOrders = [];
      print("OrderProvider: Error fetching user orders: $e");
    }

    _setLoading(false);
  }



  // Lấy chi tiết một đơn hàng của người dùng hiện tại
  Future<OrderDetailModel?> fetchOrderDetailForUser(int orderId) async {
    if (authProvider.isGuest || authProvider.user == null) {
      _errorMessage = "Vui lòng đăng nhập.";
      notifyListeners();
      return null;
    }
    final int userId = authProvider.user!.id;

    _setLoading(true);
    _clearError();
    _currentOrderDetail = null; // Xóa chi tiết cũ
    OrderDetailModel? fetchedOrder;

    try {
      // API: GET /api/orders/{orderId}/my-order?userId={userId}
      // Hoặc nếu backend dùng path: /api/users/{userId}/orders/{orderId}
      final url = Uri.parse('$_baseGeneralOrderUrl/$orderId/my-order?userId=$userId');
      print("OrderProvider: Fetching order detail from $url");

      final response = await http.get(url, headers: await _getAuthHeaders());
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        fetchedOrder = OrderDetailModel.fromJson(responseData as Map<String, dynamic>);
        _currentOrderDetail = fetchedOrder;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] as String? ?? "Lỗi tải chi tiết đơn hàng: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi lấy chi tiết đơn hàng: ${e.toString()}";
      print("OrderProvider: Error fetching order detail: $e");
    }
    _setLoading(false);
    return fetchedOrder;
  }

  // User hủy đơn hàng
  Future<bool> cancelOrderByUser(int orderId, {String? reason}) async {
    if (authProvider.isGuest || authProvider.user == null) { _errorMessage = "Vui lòng đăng nhập."; notifyListeners(); return false; }
    final int userId = authProvider.user!.id; // Cần để gọi đúng API hoặc để backend xác thực

    _setLoading(true, isStatusUpdate: true);
    _clearError();
    bool success = false;
    try {
      final url = Uri.parse('$_baseGeneralOrderUrl/$orderId/cancel-by-user?userId=$userId');
      print("OrderProvider: User ID $userId cancelling order $orderId");
      final Map<String, String?> body = {};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }
      // Backend OrderController hiện tại không nhận userId trong body cho API này,
      // mà dựa vào userId từ Principal hoặc logic service để kiểm tra quyền.

      final response = await http.put(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await fetchUserOrders(); // Tải lại danh sách đơn hàng
        if (_currentOrderDetail?.orderId == orderId) { // Nếu đang xem chi tiết đơn này
          await fetchOrderDetailForUser(orderId); // Cập nhật lại chi tiết đó
        }
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] as String? ?? "Lỗi hủy đơn hàng.";
      }
    } catch (e) { _errorMessage = "Lỗi kết nối khi hủy đơn: ${e.toString()}"; print("OrderProvider: Error cancelling order: $e"); }
    _setLoading(false, isStatusUpdate: true);
    return success;
  }

  // User xác nhận đã nhận hàng
  Future<bool> confirmDeliveryByUser(int orderId) async {
    if (authProvider.isGuest || authProvider.user == null) { _errorMessage = "Vui lòng đăng nhập."; notifyListeners(); return false; }
    final int userId = authProvider.user!.id; // Backend sẽ kiểm tra quyền

    _setLoading(true, isStatusUpdate: true);
    _clearError();
    bool success = false;
    try {
      final url = Uri.parse('$_baseGeneralOrderUrl/$orderId/confirm-delivery?userId=$userId');
      print("OrderProvider: User ID $userId confirming delivery for order $orderId");

      // API backend PUT /api/orders/{orderId}/confirm-delivery không yêu cầu body trong OrderController hiện tại
      final response = await http.put(url, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        await fetchUserOrders();
        if (_currentOrderDetail?.orderId == orderId) {
          await fetchOrderDetailForUser(orderId);
        }
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] as String? ?? "Lỗi xác nhận nhận hàng.";
      }
    } catch (e) { _errorMessage = "Lỗi kết nối khi xác nhận: ${e.toString()}"; print("OrderProvider: Error confirming delivery: $e");}
    _setLoading(false, isStatusUpdate: true);
    return success;
  }

  // ✅ PHẦN THÊM MỚI: CÁC HÀM CHO ADMIN
  /// Admin: Lấy tất cả đơn hàng với phân trang, sắp xếp và lọc (nếu có)
  Future<void> fetchAllOrdersForAdmin({
    int page = 0,
    int size = 15,
    String sort = 'createdAt,desc',
    String? status, // Thêm filter theo trạng thái
    String? searchTerm, // Thêm tìm kiếm theo mã đơn hoặc tên user
  }) async {
    if (authProvider.isGuest || authProvider.user?.role != 'admin') {
      _errorMessage = "Không có quyền truy cập.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    if (page == 0) {
      notifyListeners();
    }

    try {
      final queryParams = {
        'page': page.toString(),
        'size': size.toString(),
        'sort': sort,
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['searchTerm'] = searchTerm;
      }

      final uri = Uri.parse(_baseAdminOrderUrl).replace(queryParameters: queryParams);
      print("OrderProvider (Admin): Fetching all orders from: $uri");

      final response = await http.get(uri, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _adminOrdersPageData = PageResponse.fromJson(responseData, (json) => OrderSummaryModel.fromJson(json));

        if (page == 0) {
          _allAdminOrders = _adminOrdersPageData!.content;
        } else {
          _allAdminOrders.addAll(_adminOrdersPageData!.content);
        }
        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải đơn hàng (Admin): ${response.statusCode} - ${response.body}";
        if (page == 0) _allAdminOrders = [];
        _adminOrdersPageData = null;
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tải đơn hàng (Admin): ${e.toString()}";
      if (page == 0) _allAdminOrders = [];
      _adminOrdersPageData = null;
      print("OrderProvider (Admin): Error fetching orders: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Admin: Cập nhật trạng thái của một đơn hàng
  Future<bool> updateAdminOrderStatus(
      int orderId, String newStatus, {String? reason, String? trackingNumber}) async {

    if (authProvider.isGuest || authProvider.user?.role != 'admin') {
      _errorMessage = "Không có quyền truy cập.";
      notifyListeners();
      return false;
    }

    _setLoading(true, isStatusUpdate: true);
    _clearError();
    bool success = false;

    try {
      final url = Uri.parse('$_baseAdminOrderUrl/$orderId/status');
      final Map<String, String?> body = {
        'newStatus': newStatus,
        if (reason != null) 'cancelReason': reason,
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
      };

      print("OrderProvider (Admin): Updating order $orderId to status $newStatus");
      final response = await http.put(url, headers: await _getAuthHeaders(), body: jsonEncode(body));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final updatedOrderDetail = OrderDetailModel.fromJson(responseData as Map<String, dynamic>);
        _updateOrderInLists(updatedOrderDetail);
        success = true;
      } else {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        _errorMessage = responseData['message'] as String? ?? "Lỗi cập nhật trạng thái.";
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi cập nhật trạng thái: ${e.toString()}";
    }

    _setLoading(false, isStatusUpdate: true);
    return success;
  }

  // ✅ PHẦN THÊM MỚI: Hàm helper để cập nhật một đơn hàng trong các danh sách hiện có
  void _updateOrderInLists(OrderDetailModel updatedOrder) {
    // Chuyển đổi OrderDetailModel sang OrderSummaryModel để cập nhật danh sách
    final summaryToUpdate = OrderSummaryModel(
        orderId: updatedOrder.orderId,
        orderDate: updatedOrder.orderDate,
        firstProductImageUrl: updatedOrder.items.isNotEmpty ? updatedOrder.items.first.productImageUrl : null,
        firstProductNameOrItemCount: updatedOrder.items.isNotEmpty ? (updatedOrder.items.length > 1 ? '${updatedOrder.items.first.productName} và ${updatedOrder.items.length - 1} sản phẩm khác' : updatedOrder.items.first.productName) : 'Đơn hàng trống',
        totalQuantityOfItems: updatedOrder.items.fold(0, (sum, item) => sum + item.quantity),
        totalAmount: updatedOrder.totalAmount,
        status: updatedOrder.status,
        customerName: updatedOrder.userName,
        customerEmail: updatedOrder.userEmail,
        appliedVoucherCode: updatedOrder.appliedVoucherCode,
        voucherDiscountAmount: updatedOrder.voucherDiscountAmount
    );

    // Cập nhật trong danh sách admin
    int adminIndex = _allAdminOrders.indexWhere((order) => order.orderId == updatedOrder.orderId);
    if (adminIndex != -1) {
      _allAdminOrders[adminIndex] = summaryToUpdate;
    }

    // Cập nhật trong danh sách user (nếu user hiện tại là người đặt đơn đó)
    if (authProvider.user?.id == updatedOrder.userId) { // Giả sử OrderDetailModel có userId
      int userIndex = _userOrders.indexWhere((order) => order.orderId == updatedOrder.orderId);
      if (userIndex != -1) {
        _userOrders[userIndex] = summaryToUpdate;
      }
    }

    // Cập nhật chi tiết đơn hàng hiện tại nếu đang xem
    if (_currentOrderDetail?.orderId == updatedOrder.orderId) {
      _currentOrderDetail = updatedOrder;
    }

    notifyListeners();
  }

  // ✅ CẬP NHẬT: Hàm updateAuthProvider để reset cả danh sách admin
  void updateAuthProvider(AuthProvider newAuth) {
    if (!newAuth.isAuthenticated && authProvider.isAuthenticated) {
      _userOrders = [];
      _currentOrderDetail = null;
      _allAdminOrders = [];
      _adminOrdersPageData = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      print("OrderProvider: User logged out, cleared all order data.");
    }
  }

}

// Placeholder cho Pageable (bạn có thể tạo model này trong file riêng nếu cần dùng nhiều)
// Hoặc sử dụng một package có sẵn cho phân trang nếu muốn.
class Pageable {
  final int pageNumber;
  final int pageSize;
  final String sortProperty;
  final String sortDirection; // "asc" or "desc"

  Pageable({
    this.pageNumber = 0,
    this.pageSize = 10,
    this.sortProperty = 'createdAt',
    this.sortDirection = 'desc',
  });
}