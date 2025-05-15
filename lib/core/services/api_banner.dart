import 'dart:convert';
import 'package:http/http.dart' as http;

class BannerService {
  // URL gọi API vẫn dùng 10.0.2.2 vì app chạy trên emulator
  static const String _apiUrl = 'http://10.0.2.2:8080/api/banners';
  // Base URL đúng để truy cập ảnh từ emulator
  static const String _imageBaseUrlCorrectForEmulator = 'http://10.0.2.2:8080';
  // Base URL sai mà API trả về
  static const String _imageBaseUrlFromApi = 'http://localhost:8080';

  static Future<List<String>> fetchBannerImages() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        // Sửa đổi ở đây:
        return data.map<String>((item) {
          String imageUrlFromApi = item['imageUrl'] as String;
          // Thay thế phần URL sai bằng phần URL đúng cho emulator
          String correctImageUrl = imageUrlFromApi.replaceAll(
              _imageBaseUrlFromApi,
              _imageBaseUrlCorrectForEmulator
          );
          return correctImageUrl;
        }).toList();

      } else {
        throw Exception('Failed to load banners, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchBannerImages: $e');
      throw Exception('Error fetching banners: $e');
    }
  }
}