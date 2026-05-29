import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RoleSwitcher extends StatelessWidget {
  const RoleSwitcher({super.key});

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return '👨‍💼 Admin';
      case 'pelayan':
        return '🙏 Pelayan';
      case 'jemaat':
        return '👥 Jemaat';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userRoles = authProvider.userRoles;
        final currentRole = authProvider.currentDisplayRole;

        // Hide if only one role
        if (userRoles.isEmpty || userRoles.length == 1) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButton<String>(
            value: currentRole,
            isExpanded: false,
            underline: Container(),
            style: Theme.of(context).textTheme.bodyMedium,
            items: userRoles.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(_getRoleLabel(role)),
              );
            }).toList(),
            onChanged: (newRole) {
              if (newRole != null && newRole != currentRole) {
                authProvider.switchRole(newRole);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berganti ke: ${_getRoleLabel(newRole)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
