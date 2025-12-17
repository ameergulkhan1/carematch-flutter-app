import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../client_colors.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../services/enhanced_booking_service.dart';
import '../../../../../services/caregiver_search_service.dart';
import '../../../../../models/booking_model.dart';
import '../../../../../models/caregiver_user_model.dart';
import '../../../../../shared/utils/responsive_utils.dart';
import 'package:provider/provider.dart';

class DashboardHomePage extends StatefulWidget {
  const DashboardHomePage({super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  final EnhancedBookingService _bookingService = EnhancedBookingService();
  final CaregiverSearchService _searchService = CaregiverSearchService();

  int _activeBookings = 0;
  int _completedBookings = 0;
  int _savedCaregivers = 0;
  int _pendingPayments = 0;
  int _pendingRatings = 0;
  int _myReviewsCount = 0;
  int _activeIncidents = 0;
  double _totalSpent = 0;
  List<BookingModel> _upcomingBookings = [];
  List<CaregiverUser> _topCaregivers = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _newsUpdates = [];
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
          _loadNotifications(userId),
          _loadNewsUpdates(),
          _calculateTotalSpent(userId),
          _loadPendingRatings(userId),
          _loadMyReviewsCount(userId),
          _loadActiveIncidents(userId),
        ]);

        setState(() {
          _activeBookings = results[0] as int;
          _completedBookings = results[1] as int;
          _savedCaregivers = (results[2] as List).length;
          _upcomingBookings = results[3] as List<BookingModel>;
          _topCaregivers = results[4] as List<CaregiverUser>;
          _notifications = results[5] as List<Map<String, dynamic>>;
          _newsUpdates = results[6] as List<Map<String, dynamic>>;
          _totalSpent = results[7] as double;
          _pendingRatings = results[8] as int;
          _myReviewsCount = results[9] as int;
          _activeIncidents = results[10] as int;
          _pendingPayments = _upcomingBookings
              .where((b) => b.status == BookingStatus.pendingPayment)
              .length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
        _notifications = [];
        _newsUpdates = [];
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadNotifications(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'info',
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadNewsUpdates() async {
    // Mock news updates - in production, fetch from API or Firestore
    return [
      {
        'title': 'New Caregivers Available',
        'description': '5 new verified caregivers joined this week',
        'icon': Icons.person_add,
        'color': ClientColors.primary,
        'date': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'title': 'Winter Care Tips',
        'description': 'Essential winter care guide for elderly',
        'icon': Icons.article,
        'color': ClientColors.info,
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'title': 'Special Discount',
        'description': '15% off on first booking this month',
        'icon': Icons.local_offer,
        'color': ClientColors.success,
        'date': DateTime.now().subtract(const Duration(days: 2)),
      },
    ];
  }

  Future<double> _calculateTotalSpent(String userId) async {
    try {
      final bookings = await _bookingService.getClientBookings(userId).first;
      double total = 0.0;
      for (var booking in bookings) {
        if (booking.status == BookingStatus.completed) {
          total += booking.totalAmount;
        }
      }
      return total;
    } catch (e) {
      print('Error calculating total spent: $e');
      return 0.0;
    }
  }

  Future<int> _loadPendingRatings(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Get completed bookings without ratings
      final bookingsSnapshot = await firestore
          .collection('bookings')
          .where('clientId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      int count = 0;
      for (var doc in bookingsSnapshot.docs) {
        final bookingId = doc.id;
        // Check if review exists
        final reviewSnapshot = await firestore
            .collection('reviews')
            .where('bookingId', isEqualTo: bookingId)
            .where('reviewerId', isEqualTo: userId)
            .limit(1)
            .get();

        if (reviewSnapshot.docs.isEmpty) {
          count++;
        }
      }
      return count;
    } catch (e) {
      print('Error loading pending ratings: $e');
      return 0;
    }
  }

  Future<int> _loadMyReviewsCount(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error loading reviews count: $e');
      return 0;
    }
  }

  Future<int> _loadActiveIncidents(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('incidents')
          .where('reporterId', isEqualTo: userId)
          .where('status',
              whereIn: ['submitted', 'investigating', 'pending']).get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error loading active incidents: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final padding = ResponsiveUtils.getContentPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          _buildWelcomeCard(),
          SizedBox(height: isMobile ? 16 : 24),

          // Statistics cards
          Text(
            'Overview',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: ClientColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),

          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 40 : 60),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ClientColors.primary),
                ),
              ),
            )
          else
            _buildResponsiveStats(isMobile),

          SizedBox(height: isMobile ? 24 : 32),

          // Notifications and News section - responsive layout
          isMobile
              ? Column(
                  children: [
                    _buildNotificationsCard(),
                    const SizedBox(height: 16),
                    _buildNewsCard(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildNotificationsCard()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildNewsCard()),
                  ],
                ),

          SizedBox(height: isMobile ? 24 : 32),

          // Quick actions and upcoming - responsive layout
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTodaySchedule(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ClientColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Schedule",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ClientColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTodaySchedule(),
                        ],
                      ),
                    ),
                  ],
                ),

          SizedBox(height: isMobile ? 24 : 32),

          // Top rated caregivers
          if (_topCaregivers.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top Rated Caregivers',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: ClientColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            _buildTopCaregivers(),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsiveStats(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet =
            constraints.maxWidth > 600 && constraints.maxWidth <= 900;
        final spacing = isMobile ? 12.0 : 16.0;

        if (isMobile) {
          // Mobile: 1 column
          return Column(
            children: [
              _buildStatCard('Active Bookings', _activeBookings.toString(),
                  Icons.pending_actions, ClientColors.primary, 'In progress'),
              SizedBox(height: spacing),
              _buildStatCard('Completed', _completedBookings.toString(),
                  Icons.check_circle, ClientColors.success, 'All time'),
              SizedBox(height: spacing),
              _buildStatCard('Saved', _savedCaregivers.toString(),
                  Icons.favorite, ClientColors.danger, 'Favorites'),
              SizedBox(height: spacing),
              _buildStatCard(
                  'Total Spent',
                  '\$${_totalSpent.toStringAsFixed(0)}',
                  Icons.payments,
                  ClientColors.info,
                  'All time'),
            ],
          );
        } else if (isTablet) {
          // Tablet: 2 columns
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                        'Active',
                        _activeBookings.toString(),
                        Icons.pending_actions,
                        ClientColors.primary,
                        'In progress'),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildStatCard(
                        'Completed',
                        _completedBookings.toString(),
                        Icons.check_circle,
                        ClientColors.success,
                        'All time'),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Saved', _savedCaregivers.toString(),
                        Icons.favorite, ClientColors.danger, 'Favorites'),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: _buildStatCard(
                        'Spent',
                        '\$${_totalSpent.toStringAsFixed(0)}',
                        Icons.payments,
                        ClientColors.info,
                        'All time'),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop: 4 columns
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Active Bookings',
                    _activeBookings.toString(),
                    Icons.pending_actions,
                    ClientColors.primary,
                    'In progress'),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                    'Completed',
                    _completedBookings.toString(),
                    Icons.check_circle,
                    ClientColors.success,
                    'All time'),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                    'Saved Caregivers',
                    _savedCaregivers.toString(),
                    Icons.favorite,
                    ClientColors.danger,
                    'Favorites'),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildStatCard(
                    'Total Spent',
                    '\$${_totalSpent.toStringAsFixed(0)}',
                    Icons.payments,
                    ClientColors.info,
                    'All time'),
              ),
            ],
          );
        }
      },
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              if (trend.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: ClientColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ClientColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: ClientColors.textSecondary,
              fontWeight: FontWeight.w500,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 200;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isNarrow ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ClientColors.primary.withOpacity(0.1),
                      ClientColors.accent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isNarrow
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ClientColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _upcomingBookings.length.toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ClientColors.dark,
                                ),
                              ),
                              const Text(
                                'Appointments Today',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
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
      },
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

  Widget _buildNotificationsCard() {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClientColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: ClientColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ClientColors.dark,
                ),
              ),
              const Spacer(),
              if (_notifications.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ClientColors.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No new notifications',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _notifications.take(3).map((notification) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ClientColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                notification['type'] == 'payment'
                                    ? Icons.payment
                                    : notification['type'] == 'booking'
                                        ? Icons.calendar_today
                                        : Icons.info,
                                color: ClientColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ClientColors.dark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['message'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildNewsCard() {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClientColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.article,
                  color: ClientColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'News & Updates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ClientColors.dark,
                ),
              ),
            ],
          ),
          if (_newsUpdates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: _newsUpdates.map((news) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (news['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            news['icon'] as IconData,
                            color: news['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ClientColors.dark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                news['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(news['date'] as DateTime),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No news available',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
