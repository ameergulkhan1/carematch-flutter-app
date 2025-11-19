import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../admin_routes.dart';

class AdminTopbar extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;

  const AdminTopbar({
    super.key,
    required this.title,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          
          // Refresh Button
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: onRefresh,
            ),
          
          const SizedBox(width: 16),
          
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          
          const SizedBox(width: 16),
          
          // Admin Profile
          FutureBuilder<Map<String, dynamic>?>(
            future: AdminAuthService().getAdminDetails(),
            builder: (context, snapshot) {
              final adminDetails = snapshot.data;
              final displayName = adminDetails?['displayName'] ?? 'Admin';
              final email = adminDetails?['email'] ?? '';
              
              return PopupMenuButton<String>(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 12),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItemDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(context, value),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'profile':
        // TODO: Navigate to profile page
        break;
      case 'settings':
        Navigator.of(context).pushNamed(AdminRoutes.adminSettings);
        break;
      case 'logout':
        await _handleLogout(context);
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authService = AdminAuthService();
      await authService.adminLogout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(AdminRoutes.adminLogin);
      }
    }
  }
}

class PopupMenuItemDivider extends PopupMenuEntry<Never> {
  const PopupMenuItemDivider({super.key});

  @override
  State<PopupMenuItemDivider> createState() => _PopupMenuItemDividerState();

  @override
  double get height => 16;

  @override
  bool represents(void value) => false;
}

class _PopupMenuItemDividerState extends State<PopupMenuItemDivider> {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 16);
  }
}
