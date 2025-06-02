import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/address_models.dart';


class AddressApi {
  static const String baseUrl = 'http://10.0.2.2:8080/api/address';

  static Future<List<Province>> fetchProvinces() async {
    final response = await http.get(Uri.parse('$baseUrl/provinces'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Province.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  static Future<List<District>> fetchDistricts(String provinceCode) async {
    final response = await http.get(Uri.parse('$baseUrl/districts/$provinceCode'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List districts = data['districts'];
      return districts.map((e) => District.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load districts');
    }
  }

  static Future<List<Ward>> fetchWards(String districtCode) async {
    final response = await http.get(Uri.parse('$baseUrl/wards/$districtCode'));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List wards = data['wards'];
      return wards.map((e) => Ward.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load wards');
    }
  }
}
