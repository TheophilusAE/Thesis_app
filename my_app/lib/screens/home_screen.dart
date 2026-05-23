import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_home_screen.dart';
import 'user_home_screen.dart';
import 'pelayan_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userRoles = authProvider.userRoles;
        
        // If user is Admin, show Admin screen (Admin has all permissions)
        if (userRoles.contains('admin')) {
          return const AdminHomeScreen();
        }
        // If user is Pelayan, show Pelayan screen
        else if (userRoles.contains('pelayan')) {
          return const PelayaniHomeScreen();
        }
        // Default to Jemaat screen
        else {
          return const UserHomeScreen();
        }
      },
    );
  }
}
