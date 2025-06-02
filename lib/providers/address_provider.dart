// file: lib/providers/address_provider.dart
import 'dart:convert'; // For jsonDecode and utf8.decode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/address_models.dart'; // Import Province, District, Ward models

class AddressProvider with ChangeNotifier {
  // Base URL for your address API (points to your Spring Boot AddressController)
  // IMPORTANT: Ensure this IP is correct for your testing environment
  // For Android Emulator if backend is on localhost: 'http://10.0.2.2:8080/api/address'
  // For iOS Simulator if backend is on localhost: 'http://localhost:8080/api/address'
  // For physical device: 'http://YOUR_COMPUTER_LAN_IP:8080/api/address'
  final String _baseApiUrl = 'http://10.0.2.2:8080/api/address';

  List<Province> _provinces = [];
  List<Province> get provinces => _provinces;

  List<District> _districts = [];
  List<District> get districts => _districts;

  List<Ward> _wards = [];
  List<Ward> get wards => _wards;

  // Store the currently selected values
  Province? _selectedProvince;
  Province? get selectedProvince => _selectedProvince;

  District? _selectedDistrict;
  District? get selectedDistrict => _selectedDistrict;

  Ward? _selectedWard;
  Ward? get selectedWard => _selectedWard;

  // Loading states for each dropdown
  bool _isLoadingProvinces = false;
  bool get isLoadingProvinces => _isLoadingProvinces;

  bool _isLoadingDistricts = false;
  bool get isLoadingDistricts => _isLoadingDistricts;

  bool _isLoadingWards = false;
  bool get isLoadingWards => _isLoadingWards;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AddressProvider() {
    fetchProvinces(); // Fetch provinces when the provider is initialized
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // notifyListeners(); // Usually called by the main method after all state changes
    }
  }

  void _setLoadingProvinces(bool loading) {
    if (_isLoadingProvinces == loading) return;
    _isLoadingProvinces = loading;
    notifyListeners();
  }

  void _setLoadingDistricts(bool loading) {
    if (_isLoadingDistricts == loading) return;
    _isLoadingDistricts = loading;
    notifyListeners();
  }

  void _setLoadingWards(bool loading) {
    if (_isLoadingWards == loading) return;
    _isLoadingWards = loading;
    notifyListeners();
  }

  // Fetch the list of Provinces
  Future<void> fetchProvinces() async {
    _setLoadingProvinces(true);
    _clearError();
    // notifyListeners(); // _setLoadingProvinces already called

    try {
      final url = Uri.parse('$_baseApiUrl/provinces');
      print("AddressProvider: Fetching provinces from $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // The external API (provinces.open-api.vn/api/p/) returns a JSON array directly
        // Your backend (/api/address/provinces) forwards this JSON array as a String.
        final List<dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        _provinces = decodedData
            .map((json) => Province.fromJson(json as Map<String, dynamic>))
            .toList();
        _provinces.sort((a, b) => a.name.compareTo(b.name)); // Sort by name
        _errorMessage = null; // Clear previous error
      } else {
        _errorMessage = "Lỗi tải danh sách tỉnh/thành: ${response.statusCode}";
        _provinces = [];
        print("AddressProvider: Error fetching provinces - ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tải tỉnh/thành: ${e.toString()}";
      _provinces = [];
      print("AddressProvider: Error fetching provinces: $e");
    }
    _setLoadingProvinces(false);
    // notifyListeners(); // _setLoadingProvinces already called
  }

  // Fetch the list of Districts for a given provinceCode
  Future<void> fetchDistricts(int provinceCode) async {
    _setLoadingDistricts(true);
    _clearError();
    _districts = []; // Clear old districts
    _wards = [];     // Clear old wards
    _selectedDistrict = null; // Reset selected district
    _selectedWard = null;     // Reset selected ward
    // notifyListeners(); // _setLoadingDistricts already called

    try {
      // Your backend API: GET /api/address/districts/{provinceCode}
      // This backend API calls: https://provinces.open-api.vn/api/p/{provinceCode}?depth=2
      // The original API returns a Province object which contains a list of districts.
      // Your backend forwards this Province object as a JSON String.
      final url = Uri.parse('$_baseApiUrl/districts/$provinceCode');
      print("AddressProvider: Fetching districts for province $provinceCode from $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> provinceData = jsonDecode(utf8.decode(response.bodyBytes));
        if (provinceData['districts'] != null && provinceData['districts'] is List) {
          _districts = (provinceData['districts'] as List)
              .map((json) => District.fromJson(json as Map<String, dynamic>))
              .toList();
          _districts.sort((a, b) => a.name.compareTo(b.name)); // Sort by name
        } else {
          _districts = []; // No districts found or unexpected format
          print("AddressProvider: No 'districts' array found in response for province $provinceCode");
        }
        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải danh sách quận/huyện: ${response.statusCode}";
        _districts = [];
        print("AddressProvider: Error fetching districts - ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tải quận/huyện: ${e.toString()}";
      _districts = [];
      print("AddressProvider: Error fetching districts: $e");
    }
    _setLoadingDistricts(false);
    // notifyListeners(); // _setLoadingDistricts already called
  }

  // Fetch the list of Wards for a given districtCode
  Future<void> fetchWards(int districtCode) async {
    _setLoadingWards(true);
    _clearError();
    _wards = []; // Clear old wards
    _selectedWard = null; // Reset selected ward
    // notifyListeners(); // _setLoadingWards already called

    try {
      // Your backend API: GET /api/address/wards/{districtCode}
      // This backend API calls: https://provinces.open-api.vn/api/d/{districtCode}?depth=2
      // The original API returns a District object which contains a list of wards.
      // Your backend forwards this District object as a JSON String.
      final url = Uri.parse('$_baseApiUrl/wards/$districtCode');
      print("AddressProvider: Fetching wards for district $districtCode from $url");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> districtData = jsonDecode(utf8.decode(response.bodyBytes));
        if (districtData['wards'] != null && districtData['wards'] is List) {
          _wards = (districtData['wards'] as List)
              .map((json) => Ward.fromJson(json as Map<String, dynamic>))
              .toList();
          _wards.sort((a, b) => a.name.compareTo(b.name)); // Sort by name
        } else {
          _wards = []; // No wards found or unexpected format
          print("AddressProvider: No 'wards' array found in response for district $districtCode");
        }
        _errorMessage = null;
      } else {
        _errorMessage = "Lỗi tải danh sách phường/xã: ${response.statusCode}";
        _wards = [];
        print("AddressProvider: Error fetching wards - ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _errorMessage = "Lỗi kết nối khi tải phường/xã: ${e.toString()}";
      _wards = [];
      print("AddressProvider: Error fetching wards: $e");
    }
    _setLoadingWards(false);
    // notifyListeners(); // _setLoadingWards already called
  }

  // Update selected Province and fetch its districts
  void setSelectedProvince(Province? province) {
    if (_selectedProvince?.code != province?.code) {
      _selectedProvince = province;
      _selectedDistrict = null; // Reset district when province changes
      _selectedWard = null;     // Reset ward when province changes
      _districts = [];        // Clear districts list
      _wards = [];            // Clear wards list
      notifyListeners();      // Notify UI about changes in selectedProvince and cleared lists
      if (province != null) {
        fetchDistricts(province.code); // Fetch new districts
      }
    }
  }

  // Update selected District and fetch its wards
  void setSelectedDistrict(District? district) {
    if (_selectedDistrict?.code != district?.code) {
      _selectedDistrict = district;
      _selectedWard = null; // Reset ward when district changes
      _wards = [];        // Clear wards list
      notifyListeners();  // Notify UI about changes in selectedDistrict and cleared list
      if (district != null) {
        fetchWards(district.code); // Fetch new wards
      }
    }
  }

  // Update selected Ward
  void setSelectedWard(Ward? ward) {
    if (_selectedWard?.code != ward?.code) {
      _selectedWard = ward;
      notifyListeners(); // Notify UI about change in selectedWard
    }
  }

  // Reset all selections and dependent lists
  void resetAddressSelectionsAndData() {
    _selectedProvince = null;
    _selectedDistrict = null;
    _selectedWard = null;
    _districts = [];
    _wards = [];
    _errorMessage = null;
    // _provinces list is not cleared here, assuming it's fetched once initially
    // If you want to re-fetch provinces, call fetchProvinces()
    notifyListeners();
  }

  @override
  void dispose() {
    // No controllers to dispose in this provider
    super.dispose();
  }
}