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
        final currentDisplayRole = authProvider.currentDisplayRole;
        final userRoles = authProvider.userRoles;
        
        // Route based on currentDisplayRole instead of just checking roles
        if (currentDisplayRole == 'admin' && userRoles.contains('admin')) {
          return const AdminHomeScreen();
        } else if (currentDisplayRole == 'pelayan' && userRoles.contains('pelayan')) {
          return const PelayaniHomeScreen();
        } else if (currentDisplayRole == 'jemaat' && userRoles.contains('jemaat')) {
          return const UserHomeScreen();
        }
        
        // Fallback: if currentDisplayRole not in userRoles, show priority screen
        if (userRoles.contains('admin')) {
          return const AdminHomeScreen();
        } else if (userRoles.contains('pelayan')) {
          return const PelayaniHomeScreen();
        } else {
          return const UserHomeScreen();
        }
      },
    );
  }
}
