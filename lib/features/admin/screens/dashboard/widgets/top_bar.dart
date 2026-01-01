import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin_colors.dart';
import '../../../services/admin_auth_service.dart';
import '../../../admin_routes.dart';
import '../../../../../services/notification_service.dart';
import '../../../../../features/shared/widgets/notification_panel.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../shared/utils/responsive_utils.dart';

class AdminTopBarNew extends StatelessWidget {
  final String title;
  final bool showSearch;
  final VoidCallback? onRefresh;
  final VoidCallback? onMenuTap;

  const AdminTopBarNew({
    super.key,
    required this.title,
    this.showSearch = false,
    this.onRefresh,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      height: isMobile ? 60 : 70,
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
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getContentPadding(context),
        ),
        child: Row(
          children: [
            // Mobile Menu Button
            if (isMobile && onMenuTap != null)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuTap,
                color: AdminColors.dark,
              ),

            // Page Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 18 : (isTablet ? 20 : 24),
                  fontWeight: FontWeight.bold,
                  color: AdminColors.dark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 16),

            // Search Bar (conditional) - Hide on mobile
            if (showSearch && !isMobile)
              Container(
                constraints: BoxConstraints(maxWidth: isTablet ? 200 : 300),
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
              )
            else if (!showSearch && !isMobile)
              const Spacer(),

            // Refresh Button - Hide on mobile
            if (onRefresh != null && !isMobile) ...[
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Refresh',
                onPressed: onRefresh,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
            ],

            // Notifications
            StreamBuilder<int>(
              stream: NotificationService().getUnreadCount(
                FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      tooltip: 'Notifications',
                      onPressed: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'Notifications',
                          barrierColor: Colors.black54,
                          transitionDuration: const Duration(milliseconds: 300),
                          pageBuilder: (context, animation, secondaryAnimation) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: const NotificationPanel(),
                              ),
                            );
                          },
                        );
                      },
                      color: Colors.grey[700],
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
                        if (!isMobile) ...[
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
                      // Dashboard switching options
                      const PopupMenuItem(
                        value: 'client_dashboard',
                        child: Row(
                          children: [
                            Icon(Icons.home, color: AdminColors.primary, size: 20),
                            SizedBox(width: 12),
                            Text('Client Dashboard', style: TextStyle(color: AdminColors.primary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'caregiver_dashboard',
                        child: Row(
                          children: [
                            Icon(Icons.medical_services, color: AdminColors.secondary, size: 20),
                            SizedBox(width: 12),
                            Text('Caregiver Dashboard', style: TextStyle(color: AdminColors.secondary)),
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
      case 'client_dashboard':
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.clientDashboard);
        }
        break;
      case 'caregiver_dashboard':
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.caregiverDashboard);
        }
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
