import 'package:flutter/material.dart';
import '../client_colors.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../services/booking_service.dart';
import '../../../../../services/caregiver_search_service.dart';
import '../../../../../models/booking_model.dart';
import '../../../../../models/caregiver_user_model.dart';
import 'package:provider/provider.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  final BookingService _bookingService = BookingService();
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
        final results = await Future.wait([
          _bookingService.getActiveBookingsCount(userId),
          _bookingService.getCompletedBookingsCount(userId),
          _searchService.getFavoriteCaregivers(userId),
          _bookingService.getUpcomingBookings(userId),
          _searchService.getTopRatedCaregivers(limit: 6),
        ]);

        setState(() {
          _activeBookings = results[0] as int;
          _completedBookings = results[1] as int;
          _savedCaregivers = (results[2] as List).length;
          _upcomingBookings = results[3] as List<BookingModel>;
          _topCaregivers = results[4] as List<CaregiverUser>;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          _buildWelcomeCard(),
          const SizedBox(height: 24),

          // Statistics cards
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ClientColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Bookings',
                    _activeBookings.toString(),
                    Icons.pending_actions,
                    ClientColors.primary,
                    '+${_activeBookings * 5}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    _completedBookings.toString(),
                    Icons.check_circle,
                    ClientColors.success,
                    '+${_completedBookings * 3}%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Saved Caregivers',
                    _savedCaregivers.toString(),
                    Icons.favorite,
                    ClientColors.danger,
                    _savedCaregivers > 0 ? '+' : '',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    '\$${(_completedBookings * 250).toString()}',
                    Icons.payments,
                    ClientColors.warning,
                    'This month',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),

          // Quick actions and upcoming
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick actions (left)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Upcoming bookings (right)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.dark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTodaySchedule(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Top rated caregivers
          if (_topCaregivers.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Rated Caregivers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.dark,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTopCaregivers(),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.clientUser;
        final userName = user?.fullName ?? 'Client';

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ClientColors.primary, Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.isEmailVerified == true
                          ? 'Your account is verified and ready to use'
                          : 'Please verify your email to access all features',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Find Caregivers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: ClientColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.favorite,
                size: 120,
                color: Colors.white24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: ClientColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ClientColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.search,
        'title': 'Find Caregivers',
        'desc': 'Search for trusted professionals',
        'color': ClientColors.primary
      },
      {
        'icon': Icons.calendar_month,
        'title': 'Book Service',
        'desc': 'Schedule a new appointment',
        'color': ClientColors.success
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'View Favorites',
        'desc': 'See your saved caregivers',
        'color': ClientColors.danger
      },
      {
        'icon': Icons.message_outlined,
        'title': 'Messages',
        'desc': 'Chat with your caregivers',
        'color': ClientColors.info
      },
    ];

    return Column(
      children: actions.map((action) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action['title'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ClientColors.dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action['desc'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTodaySchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ClientColors.primary.withOpacity(0.1),
                  ClientColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ClientColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _upcomingBookings.length.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ClientColors.dark,
                        ),
                      ),
                      const Text(
                        'Appointments Today',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_upcomingBookings.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Appointment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _upcomingBookings.first.startTime ?? '10:00 AM',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.dark,
                  ),
                ),
                Text(
                  _upcomingBookings.first.caregiverName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClientColors.primary,
                  side: const BorderSide(color: ClientColors.primary),
                ),
                child: const Text('View Schedule'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Text(
              'No appointments scheduled for today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopCaregivers() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _topCaregivers.take(6).map((caregiver) {
        return Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ClientColors.primary.withOpacity(0.1),
                child: Text(
                  caregiver.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    color: ClientColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                caregiver.fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ClientColors.dark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (caregiver.specializations.isNotEmpty)
                Text(
                  caregiver.specializations.first,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: ClientColors.warning, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
