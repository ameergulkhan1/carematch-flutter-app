import 'package:flutter/material.dart';
import '../admin_colors.dart';
import '../../../services/admin_auth_service.dart';
import '../../../admin_routes.dart';

class AdminTopBarNew extends StatelessWidget {
  final String title;
  final bool showSearch;
  final VoidCallback? onRefresh;

  const AdminTopBarNew({
    Key? key,
    required this.title,
    this.showSearch = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      height: 70,
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 24),
        child: Row(
          children: [
            // Page Title
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.dark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 16),

            // Search Bar (conditional) - Hide on small screens
            if (showSearch && !isSmallScreen)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  height: 42,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              )
            else if (!showSearch)
              const Spacer(),

            // Refresh Button - Hide on very small screens
            if (onRefresh != null && !isSmallScreen) ...[
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Refresh',
                onPressed: onRefresh,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
            ],

            // Notifications
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () {
                    // TODO: Show notifications
                  },
                  color: Colors.grey[700],
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Admin Profile Dropdown
            Flexible(
              child: FutureBuilder<Map<String, dynamic>?>(
                future: AdminAuthService().getAdminDetails(),
                builder: (context, snapshot) {
                  final adminDetails = snapshot.data;
                  final displayName = adminDetails?['displayName'] ?? 'Admin';

                  return PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AdminColors.primary,
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!isSmallScreen) ...[
                          const SizedBox(width: 4),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  'Administrator',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[700], size: 20),
                        ],
                      ],
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 12),
                            const Text('Profile'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 12),
                            const Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        height: 1,
                        enabled: false,
                        child: Divider(height: 1),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'profile':
        // TODO: Navigate to profile
        break;
      case 'settings':
        Navigator.of(context).pushNamed(AdminRoutes.adminSettings);
        break;
      case 'logout':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
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
        break;
    }
  }
}
