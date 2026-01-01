import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/enhanced_booking_service.dart';
import '../../../services/caregiver_search_service.dart';
import '../../../models/booking_model.dart';
import '../../../models/caregiver_user_model.dart';
import 'search_caregivers_screen.dart';
import 'saved_caregivers_screen.dart';
import 'client_bookings_screen.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final EnhancedBookingService _bookingService = EnhancedBookingService();
  final CaregiverSearchService _searchService = CaregiverSearchService();
  
  int _activeBookings = 0;
  int _completedBookings = 0;
  int _savedCaregivers = 0;
  List<BookingModel> _upcomingBookings = [];
  List<CaregiverUser> _topCaregivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;
      
      if (userId != null) {
        // Load statistics
        final activeCount = await _bookingService.getActiveBookingsCount(userId);
        final completedCount = await _bookingService.getCompletedBookingsCount(userId);
        final savedCount = (await _searchService.getFavoriteCaregivers(userId)).length;
        
        // Load upcoming bookings
        final upcoming = await _bookingService.getUpcomingBookings(userId);
        
        // Load top caregivers
        final topCaregivers = await _searchService.getTopRatedCaregivers(limit: 6);
        
        setState(() {
          _activeBookings = activeCount;
          _completedBookings = completedCount;
          _savedCaregivers = savedCount;
          _upcomingBookings = upcoming;
          _topCaregivers = topCaregivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'CareMatch',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
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
                  const PopupMenuItem(
                    value: 'admin_dashboard',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 20, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Admin Dashboard', style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'caregiver_dashboard',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, size: 20, color: AppColors.secondary),
                        SizedBox(width: 12),
                        Text('Caregiver Dashboard', style: TextStyle(color: AppColors.secondary)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.landing);
                    }
                  } else if (value == 'admin_dashboard') {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/admin/dashboard');
                    }
                  } else if (value == 'caregiver_dashboard') {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.caregiverDashboard);
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.clientUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user.fullName}!',
                            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.isEmailVerified 
                                ? 'Your account is verified and ready to use'
                                : 'Please verify your email to access all features',
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Statistics
                    Text('Overview', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildStatCard(
                            icon: Icons.pending_actions,
                            title: 'Active Bookings',
                            value: _activeBookings.toString(),
                            color: AppColors.primary,
                          ),
                          _buildStatCard(
                            icon: Icons.check_circle,
                            title: 'Completed',
                            value: _completedBookings.toString(),
                            color: AppColors.success,
                          ),
                          _buildStatCard(
                            icon: Icons.favorite,
                            title: 'Saved Caregivers',
                            value: _savedCaregivers.toString(),
                            color: AppColors.error,
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Text('Quick Actions', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          icon: Icons.search,
                          title: 'Find Caregivers',
                          description: 'Search for trusted caregivers',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchCaregiversScreen()),
                          ),
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.calendar_month,
                          title: 'My Bookings',
                          description: 'View and manage bookings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ClientBookingsScreen()),
                          ),
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.favorite_outline,
                          title: 'Favorites',
                          description: 'Saved caregivers',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SavedCaregiversScreen()),
                          ),
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.message_outlined,
                          title: 'Messages',
                          description: 'Chat with caregivers',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.clientChat),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Upcoming Bookings
                    if (_upcomingBookings.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Upcoming Bookings', style: AppTextStyles.headlineMedium),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ClientBookingsScreen()),
                            ),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._upcomingBookings.take(3).map((booking) => _buildBookingCard(booking)),
                      const SizedBox(height: 32),
                    ],

                    // Top Caregivers
                    if (_topCaregivers.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Top Rated Caregivers', style: AppTextStyles.headlineMedium),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchCaregiversScreen()),
                            ),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _topCaregivers.map((caregiver) => _buildCaregiverCard(caregiver)).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                    const SizedBox(height: 32),

                    // Profile Summary
                    Text('Profile Information', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Email', user.email),
                          const Divider(height: 24),
                          _buildInfoRow('Phone', user.phoneNumber),
                          if (user.address != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow('Address', user.address!),
                          ],
                          if (user.city != null && user.state != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow('Location', '${user.city}, ${user.state} ${user.zipCode ?? ''}'),
                          ],
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Email Status',
                            user.isEmailVerified ? 'Verified ✓' : 'Not Verified',
                            valueColor: user.isEmailVerified ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.services.isNotEmpty ? booking.services.first : 'Service',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year} at ${booking.startTime}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(booking.status),
              style: AppTextStyles.labelSmall.copyWith(
                color: _getStatusColor(booking.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverCard(CaregiverUser caregiver) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caregiver.fullName,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      caregiver.verificationStatus == 'approved' ? 'Verified' : 'Pending',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: caregiver.verificationStatus == 'approved' ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (caregiver.specializations.isNotEmpty)
            Text(
              caregiver.specializations.take(2).join(', '),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Text(
            caregiver.yearsOfExperience != null ? '${caregiver.yearsOfExperience} years experience' : 'Experience not specified',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.success;
      case BookingStatus.pending:
      case BookingStatus.pendingPayment:
      case BookingStatus.pendingReschedule:
        return AppColors.warning;
      case BookingStatus.inProgress:
        return AppColors.info;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
      case BookingStatus.disputed:
      case BookingStatus.resolved:
        return AppColors.error;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.pendingPayment:
        return 'Awaiting Payment';
      case BookingStatus.pendingReschedule:
        return 'Reschedule Requested';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.disputed:
        return 'Disputed';
      case BookingStatus.resolved:
        return 'Resolved';
    }
  }
}
