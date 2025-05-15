import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_store_app/views/auth/login_screen.dart';

void main() {
  testWidgets('Kiểm tra nhập email không hợp lệ', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Nhập email sai định dạng
    await tester.enterText(find.byType(TextField).first, "abc");
    await tester.enterText(find.byType(TextField).last, "password123");

    await tester.tap(find.text("Đăng nhập"));
    await tester.pump();

    // Kiểm tra có thông báo lỗi không
    expect(find.text("Email không hợp lệ!"), findsOneWidget);
  });

  testWidgets('Kiểm tra mật khẩu để trống', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen()));

    // Nhập email đúng nhưng để trống mật khẩu
    await tester.enterText(find.byType(TextField).first, "user@example.com");
    await tester.enterText(find.byType(TextField).last, "");

    await tester.tap(find.text("Đăng nhập"));
    await tester.pump();

    // Kiểm tra có thông báo lỗi không
    expect(find.text("Mật khẩu không được để trống!"), findsOneWidget);
  });
}
