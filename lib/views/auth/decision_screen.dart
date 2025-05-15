// file: screens/decision_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin_panel_screen.dart';
import '../../screens/home_page.dart';
import '../../screens/welcome_screen.dart';

class DecisionScreen extends StatelessWidget {
  const DecisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.authInitStatus) {
      case AuthInitStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthInitStatus.authenticated:
        if (authProvider.isAdmin) {
          return const AdminPanelScreen(); // import nếu cần
        } else {
          return const HomePage(); // import nếu cần
        }
      case AuthInitStatus.unauthenticated:
        return const WelcomeScreen();
    }
  }
}
