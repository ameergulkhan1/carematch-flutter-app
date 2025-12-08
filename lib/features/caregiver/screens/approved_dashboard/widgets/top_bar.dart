import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../caregiver_colors.dart';
import '../../../../../services/notification_service.dart';
import '../../../../../features/shared/widgets/notification_panel.dart';
import '../../../../../core/routes/app_routes.dart';

class CaregiverTopBar extends StatelessWidget {
  final String title;
  final bool showSearch;
  final VoidCallback onLogout;

  const CaregiverTopBar({
    super.key,
    required this.title,
    this.showSearch = false,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CaregiverColors.dark,
            ),
          ),
          const Spacer(),
          if (showSearch) ...[
            _buildSearchBar(),
            const SizedBox(width: 16),
          ],
          _buildNotificationButton(),
          const SizedBox(width: 16),
          _buildProfileMenu(context),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        final userRole = snapshot.data?.get('role') as String?;
        
        return PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: CaregiverColors.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: CaregiverColors.primary, size: 20),
          ),
          itemBuilder: (context) => [
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
            if (userRole == 'admin') ...[
              const PopupMenuItem(
                value: 'admin_dashboard',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20, color: CaregiverColors.primary),
                    SizedBox(width: 12),
                    Text('Admin Dashboard', style: TextStyle(color: CaregiverColors.primary)),
                  ],
                ),
              ),
            ],
            if (userRole == 'client') ...[
              const PopupMenuItem(
                value: 'client_dashboard',
                child: Row(
                  children: [
                    Icon(Icons.home, size: 20, color: CaregiverColors.secondary),
                    SizedBox(width: 12),
                    Text('Client Dashboard', style: TextStyle(color: CaregiverColors.secondary)),
                  ],
                ),
              ),
            ],
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: CaregiverColors.danger),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(color: CaregiverColors.danger)),
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
                        backgroundColor: CaregiverColors.danger,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                onLogout();
              }
            } else if (value == 'admin_dashboard') {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/admin/dashboard');
              }
            } else if (value == 'client_dashboard') {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.clientDashboard);
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: CaregiverColors.lightGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(
        FirebaseAuth.instance.currentUser?.uid ?? '',
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
              color: CaregiverColors.dark,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: CaregiverColors.danger,
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
    );
  }
}
