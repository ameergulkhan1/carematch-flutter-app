import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../client_colors.dart';
import '../../../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../services/notification_service.dart';
import '../../../../../features/shared/widgets/notification_panel.dart';

class ClientTopBar extends StatelessWidget {
  final String title;
  final bool showSearch;

  const ClientTopBar({
    super.key,
    required this.title,
    this.showSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ClientColors.dark,
            ),
          ),
          const Spacer(),
          
          // Search bar (conditional)
          if (showSearch) ...[
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  // TODO: Implement search
                },
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Notifications
          StreamBuilder<int>(
            stream: NotificationService().getUnreadCount(
              firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
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
                    color: ClientColors.dark,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: ClientColors.danger,
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

          // Profile menu
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final userName = authProvider.clientUser?.fullName ?? 'Client';
              
              return PopupMenuButton<String>(
                offset: const Offset(0, 50),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: ClientColors.primary,
                      child: Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: ClientColors.dark),
                  ],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ClientColors.dark,
                          ),
                        ),
                        Text(
                          authProvider.clientUser?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('My Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: ClientColors.danger),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(color: ClientColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ClientColors.danger,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await authProvider.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, AppRoutes.landing);
                      }
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
