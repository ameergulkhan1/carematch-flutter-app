import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'pages/dashboard_home_page.dart';
import '../admin_users_screen.dart';
import '../admin_caregivers_screen.dart';
import '../admin_verifications_screen.dart';
import '../admin_documents_screen.dart';
import '../../services/admin_auth_service.dart';
import '../../admin_routes.dart';

class AdminDashboardMain extends StatefulWidget {
  const AdminDashboardMain({Key? key}) : super(key: key);

  @override
  State<AdminDashboardMain> createState() => _AdminDashboardMainState();
}

class _AdminDashboardMainState extends State<AdminDashboardMain> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  final _adminAuthService = AdminAuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAdmin = await _adminAuthService.isAdmin();
    if (!isAdmin && mounted) {
      Navigator.of(context).pushReplacementNamed(AdminRoutes.adminLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Row(
        children: [
          // Sidebar
          AdminSidebarNew(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            isExpanded: _isSidebarExpanded,
            onToggle: () {
              setState(() => _isSidebarExpanded = !_isSidebarExpanded);
            },
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                AdminTopBarNew(
                  title: _getPageTitle(),
                  showSearch: _selectedIndex == 0,
                  onRefresh: _selectedIndex == 0 ? () {
                    setState(() {});
                  } : null,
                ),

                // Page content
                Expanded(
                  child: _getSelectedPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Caregivers';
      case 3:
        return 'Verifications';
      case 4:
        return 'Documents';
      case 5:
        return 'Bookings';
      case 6:
        return 'Analytics';
      case 7:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHomePage();
      case 1:
        return const AdminUsersScreen();
      case 2:
        return const AdminCaregiversScreen();
      case 3:
        return const AdminVerificationsScreen();
      case 4:
        return const AdminDocumentsScreen();
      case 5:
        return _buildBookingsPage();
      case 6:
        return _buildAnalyticsPage();
      case 7:
        return _buildSettingsPage();
      default:
        return const DashboardHomePage();
    }
  }

  Widget _buildBookingsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Bookings Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon - Manage all platform bookings',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon - Platform analytics and insights',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingsSection(
                'General Settings',
                [
                  {'icon': Icons.business_outlined, 'title': 'Platform Name', 'subtitle': 'CareMatch'},
                  {'icon': Icons.email_outlined, 'title': 'Support Email', 'subtitle': 'support@carematch.com'},
                  {'icon': Icons.language_outlined, 'title': 'Default Language', 'subtitle': 'English'},
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingsSection(
                'Security',
                [
                  {'icon': Icons.security_outlined, 'title': 'Two-Factor Authentication', 'subtitle': 'Enabled'},
                  {'icon': Icons.lock_outlined, 'title': 'Password Policy', 'subtitle': 'Strong'},
                  {'icon': Icons.vpn_key_outlined, 'title': 'API Keys', 'subtitle': 'Manage API access'},
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingsSection(
                'Notifications',
                [
                  {'icon': Icons.notifications_outlined, 'title': 'Email Notifications', 'subtitle': 'Configure email alerts'},
                  {'icon': Icons.sms_outlined, 'title': 'SMS Notifications', 'subtitle': 'Configure SMS alerts'},
                  {'icon': Icons.admin_panel_settings_outlined, 'title': 'Admin Alerts', 'subtitle': 'Manage admin notifications'},
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AdminColors.dark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: AdminColors.primary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {},
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
