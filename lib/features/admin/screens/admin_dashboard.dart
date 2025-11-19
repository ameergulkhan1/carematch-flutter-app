import 'package:flutter/material.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_topbar.dart';
import '../widgets/stat_card.dart';
import '../services/admin_service.dart';
import '../services/admin_auth_service.dart';
import '../admin_routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _adminService = AdminService();
  final _adminAuthService = AdminAuthService();
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _loadStatistics();
  }

  Future<void> _checkAuth() async {
    final isAdmin = await _adminAuthService.isAdmin();
    if (!isAdmin && mounted) {
      Navigator.of(context).pushReplacementNamed(AdminRoutes.adminLogin);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final stats = await _adminService.getStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          const AdminSidebar(currentRoute: AdminRoutes.adminDashboard),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                AdminTopbar(
                  title: 'Dashboard',
                  onRefresh: _loadStatistics,
                ),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Statistics Cards
                              _buildStatisticsSection(),
                              const SizedBox(height: 32),
                              
                              // Recent Activity
                              _buildRecentActivitySection(),
                              const SizedBox(height: 32),
                              
                              // Quick Actions
                              _buildQuickActionsSection(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: _getGridCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: 'Total Users',
              value: _statistics['totalUsers']?.toString() ?? '0',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminUsers),
            ),
            StatCard(
              title: 'Clients',
              value: _statistics['totalClients']?.toString() ?? '0',
              icon: Icons.person,
              color: Colors.green,
              onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminUsers),
            ),
            StatCard(
              title: 'Caregivers',
              value: _statistics['totalCaregivers']?.toString() ?? '0',
              icon: Icons.medical_services,
              color: Colors.orange,
              onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminCaregivers),
            ),
            StatCard(
              title: 'Verified Caregivers',
              value: _statistics['verifiedCaregivers']?.toString() ?? '0',
              icon: Icons.verified,
              color: Colors.teal,
              onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminCaregivers),
            ),
            StatCard(
              title: 'Pending Verifications',
              value: _statistics['pendingVerifications']?.toString() ?? '0',
              icon: Icons.pending_actions,
              color: Colors.amber,
              onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminVerifications),
            ),
            StatCard(
              title: 'Total Bookings',
              value: _statistics['totalBookings']?.toString() ?? '0',
              icon: Icons.calendar_today,
              color: Colors.purple,
              onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminBookings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: Icons.person_add,
              title: 'New User Registration',
              subtitle: 'A new client has joined the platform',
              time: '2 minutes ago',
              color: Colors.green,
            ),
            const Divider(),
            _buildActivityItem(
              icon: Icons.verified_user,
              title: 'Caregiver Verified',
              subtitle: 'Sarah Johnson has been verified',
              time: '15 minutes ago',
              color: Colors.blue,
            ),
            const Divider(),
            _buildActivityItem(
              icon: Icons.pending,
              title: 'Pending Verification',
              subtitle: 'New verification request from John Doe',
              time: '1 hour ago',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionButton(
                  icon: Icons.person_add,
                  label: 'View Users',
                  onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminUsers),
                ),
                _buildQuickActionButton(
                  icon: Icons.verified,
                  label: 'Verifications',
                  onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminVerifications),
                ),
                _buildQuickActionButton(
                  icon: Icons.description,
                  label: 'Documents',
                  onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminDocuments),
                ),
                _buildQuickActionButton(
                  icon: Icons.calendar_today,
                  label: 'Bookings',
                  onTap: () => Navigator.of(context).pushNamed(AdminRoutes.adminBookings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  int _getGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
