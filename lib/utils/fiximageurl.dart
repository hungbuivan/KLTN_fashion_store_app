// lib/utils/utils.dart
const String baseUrl = 'http:/10.0.2.2:8080'; // dùng IP này nếu bạn test trên Android Emulator
// Nếu test trên thiết bị thật, thay 10.0.2.2 bằng IP thật của máy

String fixImageUrl(String relativePath) {
  return '$baseUrl/uploads/$relativePath';
}
