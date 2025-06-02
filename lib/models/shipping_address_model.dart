// file: lib/models/shipping_address_model.dart

class ShippingAddressModel {
  final String fullNameReceiver;
  final String phoneReceiver;
  final String street;       // Số nhà, tên đường
  final String wardName;     // Tên Phường/Xã
  final String districtName; // Tên Quận/Huyện
  final String provinceName; // Tên Tỉnh/Thành phố

  ShippingAddressModel({
    required this.fullNameReceiver,
    required this.phoneReceiver,
    required this.street,
    required this.wardName,
    required this.districtName,
    required this.provinceName,
  });

  factory ShippingAddressModel.fromJson(Map<String, dynamic> json) {
    return ShippingAddressModel(
      fullNameReceiver: json['fullNameReceiver'] as String? ?? 'N/A',
      phoneReceiver: json['phoneReceiver'] as String? ?? 'N/A',
      street: json['street'] as String? ?? 'N/A',
      wardName: json['wardName'] as String? ?? 'N/A',
      districtName: json['districtName'] as String? ?? 'N/A',
      provinceName: json['provinceName'] as String? ?? 'N/A',
    );
  }

  // Để tạo chuỗi địa chỉ đầy đủ từ các thành phần
  String get fullAddressString {
    List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (wardName.isNotEmpty) parts.add(wardName);
    if (districtName.isNotEmpty) parts.add(districtName);
    if (provinceName.isNotEmpty) parts.add(provinceName);
    return parts.join(', ');
  }

  // Dùng để gửi lên API tạo đơn hàng (nếu backend nhận object ShippingAddressDTO)
  Map<String, dynamic> toJson() {
    return {
      'fullNameReceiver': fullNameReceiver,
      'phoneReceiver': phoneReceiver,
      'street': street,
      'wardName': wardName,
      'districtName': districtName,
      'provinceName': provinceName,
    };
  }
}