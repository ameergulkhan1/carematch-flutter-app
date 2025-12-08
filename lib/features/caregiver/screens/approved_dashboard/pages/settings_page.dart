import 'package:flutter/material.dart';
import '../../../../../services/auth_service.dart';
import '../caregiver_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _auth = AuthService();
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Account Settings', [
            _buildSettingsTile(
              Icons.person_outline,
              'Edit Profile',
              'Update your personal information',
              () {},
            ),
            _buildSettingsTile(
              Icons.lock_outline,
              'Change Password',
              'Update your password',
              () {},
            ),
            _buildSettingsTile(
              Icons.notifications_outlined,
              'Notifications',
              'Manage notification preferences',
              () {},
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('App Settings', [
            _buildSettingsTile(
              Icons.language_outlined,
              'Language',
              'English',
              () {},
            ),
            _buildSettingsTile(
              Icons.dark_mode_outlined,
              'Dark Mode',
              'Switch between light and dark theme',
              () {},
              trailing: Switch(
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
                activeThumbColor: CaregiverColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Support', [
            _buildSettingsTile(
              Icons.help_outline,
              'Help Center',
              'Get help and support',
              () {},
            ),
            _buildSettingsTile(
              Icons.info_outline,
              'About',
              'App version 1.0.0',
              () {},
            ),
          ]),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CaregiverColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CaregiverColors.dark,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CaregiverColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: CaregiverColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CaregiverColors.dark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
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

    if (confirm == true && mounted) {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }
}
