import 'package:flutter/material.dart';
import '../admin_routes.dart';
import '../services/admin_auth_service.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  route: AdminRoutes.adminDashboard,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.people,
                  label: 'Users',
                  route: AdminRoutes.adminUsers,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.medical_services,
                  label: 'Caregivers',
                  route: AdminRoutes.adminCaregivers,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.verified_user,
                  label: 'Verifications',
                  route: AdminRoutes.adminVerifications,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.description,
                  label: 'Documents',
                  route: AdminRoutes.adminDocuments,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Bookings',
                  route: AdminRoutes.adminBookings,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.analytics,
                  label: 'Analytics',
                  route: AdminRoutes.adminAnalytics,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  route: AdminRoutes.adminSettings,
                ),
              ],
            ),
          ),
          
          // Logout Button
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isActive = currentRoute == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
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
