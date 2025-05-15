import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String userName = "Guest";
  String userEmail = "No email";
  String? profileImage; // Nếu null thì không có ảnh

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Gọi API để lấy dữ liệu user
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:8080/"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userName = data["name"] ?? "Guest";
          userEmail = data["email"] ?? "No email";
          profileImage = data["avatar"]; // Nếu null thì không hiện ảnh
        });
      } else {
        print("Lỗi: Không thể tải dữ liệu người dùng.");
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildProfileOption(Icons.shopping_bag_outlined, "My Orders"),
                  _buildProfileOption(Icons.favorite_border, "Favorites"), 
                  _buildProfileOption(Icons.dark_mode_outlined, "Appearance"),
                  _buildProfileOption(Icons.notifications_none, "Notification"),
                  _buildProfileOption(Icons.lock_outline, "Privacy"),
                  _buildProfileOption(Icons.logout, "Sign Out"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.black54),
              onPressed: () {},
            ),
          ),
          CircleAvatar(
            radius: 40,
            backgroundImage: profileImage != null ? NetworkImage(profileImage!) : null,
            child: profileImage == null ? Icon(Icons.person, size: 40, color: Colors.grey) : null,
          ),
          SizedBox(height: 10),
          Text(userName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(userEmail, style: TextStyle(color: Colors.grey[600])),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
