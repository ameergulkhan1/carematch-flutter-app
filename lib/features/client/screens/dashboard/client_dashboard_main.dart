import 'package:flutter/material.dart';
import 'client_colors.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'pages/dashboard_home_page.dart';
import '../search_caregivers_screen.dart';
import '../client_bookings_screen.dart';
import '../saved_caregivers_screen.dart';

class ClientDashboardMain extends StatefulWidget {
  const ClientDashboardMain({Key? key}) : super(key: key);

  @override
  State<ClientDashboardMain> createState() => _ClientDashboardMainState();
}

class _ClientDashboardMainState extends State<ClientDashboardMain> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.background,
      body: Row(
        children: [
          // Sidebar
          ClientSidebar(
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
                ClientTopBar(
                  title: _getPageTitle(),
                  showSearch: _selectedIndex == 1,
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
        return 'Find Caregivers';
      case 2:
        return 'My Bookings';
      case 3:
        return 'Favorites';
      case 4:
        return 'Messages';
      case 5:
        return 'Profile';
      case 6:
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
        return const SearchCaregiversScreen();
      case 2:
        return const ClientBookingsScreen();
      case 3:
        return const SavedCaregiversScreen();
      case 4:
        return _buildMessagesPage();
      case 5:
        return _buildProfilePage();
      case 6:
        return _buildSettingsPage();
      default:
        return const DashboardHomePage();
    }
  }

  Widget _buildMessagesPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Messages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon - Chat with your caregivers',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: ClientColors.primary,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'john.doe@example.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ClientColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                'Account Settings',
                [
                  {'icon': Icons.person_outline, 'title': 'Edit Profile', 'subtitle': 'Update your personal information'},
                  {'icon': Icons.lock_outline, 'title': 'Change Password', 'subtitle': 'Update your password'},
                  {'icon': Icons.email_outlined, 'title': 'Email Preferences', 'subtitle': 'Manage email notifications'},
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingsSection(
                'Preferences',
                [
                  {'icon': Icons.notifications_outlined, 'title': 'Notifications', 'subtitle': 'Manage push notifications'},
                  {'icon': Icons.language_outlined, 'title': 'Language', 'subtitle': 'English'},
                  {'icon': Icons.dark_mode_outlined, 'title': 'Dark Mode', 'subtitle': 'Switch theme'},
                ],
              ),
              const SizedBox(height: 24),
              _buildSettingsSection(
                'Support',
                [
                  {'icon': Icons.help_outline, 'title': 'Help Center', 'subtitle': 'Get help and support'},
                  {'icon': Icons.info_outline, 'title': 'About', 'subtitle': 'App version 1.0.0'},
                  {'icon': Icons.privacy_tip_outlined, 'title': 'Privacy Policy', 'subtitle': 'View privacy policy'},
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
            color: ClientColors.dark,
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
                        color: ClientColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: ClientColors.primary,
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
