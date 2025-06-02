// file: lib/models/address_models.dart

// Model cho Tỉnh/Thành phố
class Province {
  final int code; // Mã tỉnh/thành phố
  final String name;
  final String divisionType;
  final List<District> districts; // Sẽ có nếu API trả về với depth=2

  Province({
    required this.code,
    required this.name,
    required this.divisionType,
    this.districts = const [],
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    List<District> districtsList = [];
    if (json['districts'] != null && json['districts'] is List) {
      districtsList = (json['districts'] as List)
          .map((districtJson) => District.fromJson(districtJson as Map<String, dynamic>))
          .toList();
    }
    return Province(
      code: json['code'] as int,
      name: json['name'] as String,
      divisionType: json['division_type'] as String? ?? '',
      districts: districtsList,
    );
  }

  // Giúp DropdownButtonFormField hiển thị tên thay vì 'Instance of Province'
  @override
  String toString() => name;

  // Cần thiết để so sánh các đối tượng Province trong DropdownButtonFormField
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Province && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

// Model cho Quận/Huyện
class District {
  final int code; // Mã quận/huyện
  final String name;
  final String divisionType;
  final int provinceCode;
  final List<Ward> wards; // Sẽ có nếu API trả về với depth=2

  District({
    required this.code,
    required this.name,
    required this.divisionType,
    required this.provinceCode,
    this.wards = const [],
  });

  factory District.fromJson(Map<String, dynamic> json) {
    List<Ward> wardsList = [];
    if (json['wards'] != null && json['wards'] is List) {
      wardsList = (json['wards'] as List)
          .map((wardJson) => Ward.fromJson(wardJson as Map<String, dynamic>))
          .toList();
    }
    return District(
      code: json['code'] as int,
      name: json['name'] as String,
      divisionType: json['division_type'] as String? ?? '',
      provinceCode: json['province_code'] as int,
      wards: wardsList,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is District && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

// Model cho Phường/Xã
class Ward {
  final int code; // Mã phường/xã
  final String name;
  final String divisionType;
  final int districtCode;

  Ward({
    required this.code,
    required this.name,
    required this.divisionType,
    required this.districtCode,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['code'] as int,
      name: json['name'] as String,
      divisionType: json['division_type'] as String? ?? '',
      districtCode: json['district_code'] as int,
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Ward && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}