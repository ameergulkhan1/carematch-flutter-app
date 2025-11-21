import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../admin_colors.dart';
import '../../../services/admin_service.dart';
import '../../../admin_routes.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({Key? key}) : super(key: key);

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  final _adminService = AdminService();
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AdminColors.primary,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          _buildWelcomeCard(),
          const SizedBox(height: 24),

          // Statistics Cards
          _buildStatisticsCards(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdminColors.primary, Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back, Admin! 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Here\'s what\'s happening on your platform today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Strictest: 1 column for <400px
        int crossAxisCount;
        if (constraints.maxWidth < 400) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }
        // Calculate optimal aspect ratio based on card width
        final spacing = 16.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
        double aspectRatio;
        if (constraints.maxWidth < 400) {
          aspectRatio = 0.7;
        } else if (cardWidth < 130) {
          aspectRatio = 0.85;
        } else if (cardWidth < 160) {
          aspectRatio = 1.0;
        } else if (cardWidth < 200) {
          aspectRatio = 1.2;
        } else {
          aspectRatio = 1.35;
        }
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              'Total Users',
              _statistics['totalUsers']?.toString() ?? '0',
              Icons.people_outline,
              AdminColors.info,
              '+12%',
            ),
            _buildStatCard(
              'Clients',
              _statistics['totalClients']?.toString() ?? '0',
              Icons.person_outline,
              AdminColors.success,
              '+8%',
            ),
            _buildStatCard(
              'Caregivers',
              _statistics['totalCaregivers']?.toString() ?? '0',
              Icons.medical_services_outlined,
              AdminColors.warning,
              '+15%',
            ),
            _buildStatCard(
              'Pending Verifications',
              _statistics['pendingVerifications']?.toString() ?? '0',
              Icons.pending_actions_outlined,
              AdminColors.danger,
              null,
            ),
            _buildStatCard(
              'Verified Caregivers',
              _statistics['verifiedCaregivers']?.toString() ?? '0',
              Icons.verified_user_outlined,
              const Color(0xFF14B8A6),
              '+5%',
            ),
            _buildStatCard(
              'Total Bookings',
              _statistics['totalBookings']?.toString() ?? '0',
              Icons.calendar_today_outlined,
              AdminColors.primary,
              '+20%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String? trend) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 150;
        final padding = isSmall ? 12.0 : 16.0;
        final iconSize = isSmall ? 20.0 : 24.0;
        final valueSize = isSmall ? 22.0 : 28.0;
        final titleSize = isSmall ? 11.0 : 13.0;
        
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmall ? 8 : 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),
                  if (trend != null && !isSmall)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          trend,
                          style: const TextStyle(
                            color: AdminColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.dark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AdminColors.dark,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Strictest: 1 column for <400px
            int crossAxisCount;
            if (constraints.maxWidth < 400) {
              crossAxisCount = 1;
            } else if (constraints.maxWidth > 900) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth > 400) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }
            // Calculate optimal aspect ratio based on card width
            final spacing = 16.0;
            final totalSpacing = spacing * (crossAxisCount - 1);
            final cardWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
            double aspectRatio;
            if (constraints.maxWidth < 400) {
              aspectRatio = 0.7;
            } else if (cardWidth < 100) {
              aspectRatio = 0.75;
            } else if (cardWidth < 140) {
              aspectRatio = 0.95;
            } else if (cardWidth < 180) {
              aspectRatio = 1.3;
            } else {
              aspectRatio = 1.5;
            }
            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: aspectRatio,
              children: [
                _buildActionCard(
                  'Manage Users',
                  Icons.people_outline,
                  AdminColors.info,
                  () => Navigator.of(context).pushNamed(AdminRoutes.adminUsers),
                ),
                _buildActionCard(
                  'Verify Caregivers',
                  Icons.verified_user_outlined,
                  AdminColors.success,
                  () => Navigator.of(context).pushNamed(AdminRoutes.adminVerifications),
                ),
                _buildActionCard(
                  'View Documents',
                  Icons.description_outlined,
                  AdminColors.warning,
                  () => Navigator.of(context).pushNamed(AdminRoutes.adminDocuments),
                ),
                _buildActionCard(
                  'View Reports',
                  Icons.analytics_outlined,
                  AdminColors.primary,
                  () {},
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 130;
        final padding = isSmall ? 12.0 : 16.0;
        final iconPadding = isSmall ? 8.0 : 12.0;
        final iconSize = isSmall ? 24.0 : 32.0;
        final fontSize = isSmall ? 12.0 : 14.0;
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(height: isSmall ? 8 : 12),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.dark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.dark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'New User Registration',
            'A new client has joined the platform',
            '2 minutes ago',
            Icons.person_add_outlined,
            AdminColors.success,
          ),
          const Divider(height: 24),
          _buildActivityItem(
            'Caregiver Verified',
            'Sarah Johnson has been verified',
            '15 minutes ago',
            Icons.verified_user_outlined,
            AdminColors.info,
          ),
          const Divider(height: 24),
          _buildActivityItem(
            'New Booking',
            'Booking request submitted by John Doe',
            '1 hour ago',
            Icons.calendar_today_outlined,
            AdminColors.primary,
          ),
          const Divider(height: 24),
          _buildActivityItem(
            'Document Uploaded',
            'New verification document submitted',
            '2 hours ago',
            Icons.upload_file_outlined,
            AdminColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
