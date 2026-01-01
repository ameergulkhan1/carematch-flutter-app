import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/enhanced_booking_service.dart';
import '../../../models/booking_model.dart';
import 'dashboard/client_colors.dart';
import 'payment/mock_payment_screen.dart';
import '../../../shared/widgets/rating_dialog.dart';
import '../../shared/screens/incidents/incident_report_screen.dart';

class ClientBookingsScreen extends StatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  State<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends State<ClientBookingsScreen> {
  final EnhancedBookingService _bookingService = EnhancedBookingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BookingModel> _bookings = [];
  Map<String, BookingStatus> _previousStatuses =
      {}; // Track previous booking statuses
  Set<String> _ratedBookings = {}; // Track which bookings have been rated
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, active, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      print('📋 Loading bookings for user: $userId');

      if (userId != null) {
        _bookingService.getClientBookings(userId).listen((bookings) {
          print('📋 Received ${bookings.length} bookings from stream');

          // Check for newly completed bookings that need rating
          for (var booking in bookings) {
            if (booking.status == BookingStatus.completed &&
                _previousStatuses.containsKey(booking.id) &&
                _previousStatuses[booking.id] != BookingStatus.completed &&
                !_ratedBookings.contains(booking.id)) {
              // Booking just completed - check if it needs rating
              _checkAndPromptRating(booking);
            }
            // Update status tracker
            _previousStatuses[booking.id] = booking.status;
          }

          if (mounted) {
            setState(() {
              _bookings = bookings;
              _isLoading = false;
            });
          }
        }, onError: (error) {
          print('❌ Error in bookings stream: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        });
      } else {
        print('❌ No user ID found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndPromptRating(BookingModel booking) async {
    try {
      // Check if review already exists
      final reviewSnapshot = await _firestore
          .collection('reviews')
          .where('bookingId', isEqualTo: booking.id)
          .where('reviewerId', isEqualTo: booking.clientId)
          .limit(1)
          .get();

      if (reviewSnapshot.docs.isEmpty && mounted) {
        // No review exists - show rating dialog automatically
        print(
            '⭐ Prompting rating for completed booking: ${booking.bookingRequestId}');

        // Add to rated set to prevent duplicate prompts
        _ratedBookings.add(booking.id);

        // Show rating dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          _showAutoRatingDialog(booking);
        }
      }
    } catch (e) {
      print('❌ Error checking rating status: $e');
    }
  }

  Future<void> _showAutoRatingDialog(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.rate_review, color: ClientColors.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Session Completed!',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your session with ${booking.caregiverName} has ended.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Please share your experience',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your feedback helps us maintain quality care services.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rate Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Rate Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // User chose to rate now - show rating dialog
      _showRatingDialog(booking);
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  List<BookingModel> get _filteredBookings {
    switch (_selectedFilter) {
      case 'active':
        return _bookings
            .where((b) =>
                b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.inProgress ||
                b.status == BookingStatus.pending ||
                b.status == BookingStatus.pendingPayment)
            .toList();
      case 'completed':
        return _bookings
            .where((b) => b.status == BookingStatus.completed)
            .toList();
      case 'cancelled':
        return _bookings
            .where((b) =>
                b.status == BookingStatus.cancelled ||
                b.status == BookingStatus.rejected)
            .toList();
      default:
        return _bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', _bookings.length),
                const SizedBox(width: 12),
                _buildFilterChip(
                    'Active',
                    'active',
                    _bookings
                        .where((b) =>
                            b.status == BookingStatus.confirmed ||
                            b.status == BookingStatus.inProgress)
                        .length),
                const SizedBox(width: 12),
                _buildFilterChip(
                    'Completed',
                    'completed',
                    _bookings
                        .where((b) => b.status == BookingStatus.completed)
                        .length),
                const SizedBox(width: 12),
                _buildFilterChip(
                    'Cancelled',
                    'cancelled',
                    _bookings
                        .where((b) =>
                            b.status == BookingStatus.cancelled ||
                            b.status == BookingStatus.rejected)
                        .length),
              ],
            ),
          ),
        ),

        // Bookings list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _filteredBookings.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(_filteredBookings[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? ClientColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ClientColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : ClientColors.dark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: ClientColors.primary.withOpacity(0.1),
                    child: Text(
                      booking.caregiverName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.caregiverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ClientColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.bookingRequestId,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Show rating if booking has been rated
              if (booking.status == BookingStatus.completed &&
                  booking.rating != null &&
                  booking.rating! > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Rating: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < booking.rating!
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: index < booking.rating!
                              ? Colors.amber.shade700
                              : Colors.grey.shade400,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '(${_getRatingText(booking.rating!)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Date',
                      DateFormat('MMM dd, yyyy').format(booking.startDate),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Time',
                      '${booking.startTime} - ${booking.endTime}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.medical_services,
                      'Service',
                      _getServiceTypeText(booking.serviceType),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.payments,
                      'Total',
                      '\$${booking.totalAmount.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              if (booking.status == BookingStatus.pending ||
                  booking.status == BookingStatus.pendingPayment ||
                  booking.status == BookingStatus.completed) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (booking.status == BookingStatus.pending)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelBooking(booking),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ClientColors.danger,
                            side: const BorderSide(color: ClientColors.danger),
                          ),
                        ),
                      ),
                    if (booking.status == BookingStatus.pendingPayment) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelBooking(booking),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ClientColors.danger,
                            side: const BorderSide(color: ClientColors.danger),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _proceedToPayment(booking),
                          icon: const Icon(Icons.payment, size: 18),
                          label: const Text('Pay Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClientColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    // Report Issue button for confirmed/in-progress bookings
                    if (booking.status == BookingStatus.confirmed ||
                        booking.status == BookingStatus.inProgress) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reportIssue(booking),
                          icon: const Icon(Icons.report_problem, size: 18),
                          label: const Text('Report Issue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            side: BorderSide(color: Colors.orange.shade700),
                          ),
                        ),
                      ),
                    ],
                    // Rating button for completed bookings
                    if (booking.status == BookingStatus.completed) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRatingDialog(booking),
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Rate Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClientColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ClientColors.dark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No bookings yet'
                : 'No ${_selectedFilter} bookings',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ClientColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book a caregiver to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.completed:
        return ClientColors.success;
      case BookingStatus.inProgress:
        return ClientColors.info;
      case BookingStatus.pending:
      case BookingStatus.pendingPayment:
        return ClientColors.warning;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return ClientColors.danger;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.pendingPayment:
        return 'Awaiting Payment';
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
      default:
        return status.toString().split('.').last;
    }
  }

  String _getServiceTypeText(ServiceType type) {
    switch (type) {
      case ServiceType.childcare:
        return 'Childcare';
      case ServiceType.eldercare:
        return 'Eldercare';
      case ServiceType.specialNeeds:
        return 'Special Needs';
      case ServiceType.companionship:
        return 'Companionship';
      case ServiceType.medicalCare:
        return 'Medical Care';
      default:
        return type.toString().split('.').last;
    }
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ClientColors.dark,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Booking ID', booking.bookingRequestId),
              _buildDetailRow('Caregiver', booking.caregiverName),
              _buildDetailRow(
                  'Service', _getServiceTypeText(booking.serviceType)),
              _buildDetailRow('Date',
                  DateFormat('EEEE, MMM dd, yyyy').format(booking.startDate)),
              _buildDetailRow(
                  'Time', '${booking.startTime} - ${booking.endTime}'),
              _buildDetailRow('Duration', '${booking.totalHours} hours'),
              _buildDetailRow(
                  'Hourly Rate', '\$${booking.hourlyRate.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Total Amount', '\$${booking.totalAmount.toStringAsFixed(2)}',
                  isHighlight: true),
              _buildDetailRow('Status', _getStatusText(booking.status)),
              if (booking.specialRequirements != null &&
                  booking.specialRequirements!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Special Requirements',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ClientColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.specialRequirements ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? ClientColors.primary : ClientColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: ClientColors.danger),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.uid;
        if (userId != null) {
          await _bookingService.cancelBooking(
            booking.id,
            userId,
            'Cancelled by client',
            isCaregiver: false,
          );
        }
        _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _proceedToPayment(BookingModel booking) async {
    // Navigate to mock payment screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MockPaymentScreen(
          booking: booking,
          amount: booking.totalAmount,
        ),
      ),
    );

    // If payment was successful, refresh bookings
    if (result == true && mounted) {
      _loadBookings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Payment completed successfully! Your booking is confirmed.'),
          backgroundColor: ClientColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showRatingDialog(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        booking: booking,
        reviewerType: 'client',
        onRatingSubmitted: () => _loadBookings(),
      ),
    );

    if (result == true && mounted) {
      _loadBookings(); // Refresh bookings list
    }
  }

  void _reportIssue(BookingModel booking) async {
    // Show options dialog
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Report Issue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What issue would you like to report?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            _buildIssueOption(
              context,
              'No Show',
              'Caregiver didn\'t arrive at scheduled time',
              Icons.person_off,
              Colors.red,
              'noShow',
            ),
            const Divider(height: 24),
            _buildIssueOption(
              context,
              'Late Arrival',
              'Caregiver arrived significantly late',
              Icons.access_time,
              Colors.orange,
              'lateArrival',
            ),
            const Divider(height: 24),
            _buildIssueOption(
              context,
              'Other Issue',
              'Report a different problem',
              Icons.report,
              Colors.blue,
              'other',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (option != null && mounted) {
      if (option == 'noShow') {
        _handleNoShow(booking);
      } else {
        // Navigate to general incident report screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IncidentReportScreen(
              booking: booking,
              caregiverId: booking.caregiverId,
              caregiverName: booking.caregiverName,
            ),
          ),
        );

        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Issue reported successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBookings();
        }
      }
    }
  }

  Widget _buildIssueOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String value,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNoShow(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_off, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Report No-Show'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report that ${booking.caregiverName} did not show up?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'What happens next:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBullet('Admin will investigate the incident'),
                  _buildBullet('You will receive a full refund'),
                  _buildBullet('Caregiver will be notified'),
                  _buildBullet('Case resolved within 24-48 hours'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Report No-Show'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _processNoShow(booking);
    }
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processNoShow(BookingModel booking) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final firestore = FirebaseFirestore.instance;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      if (userId == null) throw Exception('User not authenticated');

      // 1. Create incident report
      final incidentNumber = 'INC-${DateTime.now().millisecondsSinceEpoch}';
      await firestore.collection('incidents').add({
        'incidentNumber': incidentNumber,
        'type': 'noShow',
        'severity': 'high',
        'status': 'submitted',
        'reporterId': userId,
        'reporterName': booking.clientName,
        'reporterRole': 'client',
        'bookingId': booking.id,
        'caregiverId': booking.caregiverId,
        'caregiverName': booking.caregiverName,
        'clientId': booking.clientId,
        'clientName': booking.clientName,
        'title': 'Caregiver No-Show Reported',
        'description':
            'Client reported that caregiver ${booking.caregiverName} did not arrive for the scheduled booking on ${DateFormat('MMM dd, yyyy').format(booking.startDate)}.',
        'incidentDate': Timestamp.fromDate(booking.startDate),
        'reportedAt': FieldValue.serverTimestamp(),
        'timeline': [
          {
            'timestamp': FieldValue.serverTimestamp(),
            'action': 'No-show reported by client',
            'performedBy': booking.clientName,
            'notes': 'Client reported caregiver did not show up',
          }
        ],
        'tags': ['no-show', 'high-priority', 'refund-required'],
        'notifyAuthorities': false,
      });

      // 2. Update booking status
      await firestore.collection('bookings').doc(booking.id).update({
        'status': 'disputed',
        'disputeReason': 'Caregiver no-show',
        'disputedAt': FieldValue.serverTimestamp(),
        'clientApprovalStatus': 'disputed',
      });

      // 3. Create refund request
      await firestore.collection('refunds').add({
        'bookingId': booking.id,
        'transactionId': 'TXN-${booking.id}',
        'clientId': booking.clientId,
        'clientName': booking.clientName,
        'caregiverId': booking.caregiverId,
        'caregiverName': booking.caregiverName,
        'originalAmount': booking.finalAmount,
        'refundAmount': booking.finalAmount,
        'processingFee': 0,
        'netRefund': booking.finalAmount,
        'reason': 'noShow',
        'reasonDescription': 'Caregiver no-show - Full refund',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'requiresApproval': true,
        'isPartialRefund': false,
        'isApproved': null,
        'approvedBy': null,
        'approvedAt': null,
      });

      // 4. Notify admin
      await firestore.collection('notifications').add({
        'userId': 'admin',
        'type': 'incident_created',
        'title': '🚨 No-Show Reported',
        'message':
            'Client ${booking.clientName} reported a no-show for booking ${booking.bookingRequestId}. Full refund requested.',
        'data': {
          'bookingId': booking.id,
          'incidentNumber': incidentNumber,
          'amount': booking.finalAmount,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Notify caregiver
      await firestore.collection('notifications').add({
        'userId': booking.caregiverId,
        'type': 'incident_created',
        'title': 'No-Show Reported',
        'message':
            'A client has reported you as a no-show. Please contact support immediately.',
        'data': {
          'bookingId': booking.id,
          'incidentNumber': incidentNumber,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('Report Submitted'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your no-show report has been submitted.',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident: $incidentNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Admin will review within 24 hours\n'
                        '• Full refund will be processed\n'
                        '• You\'ll receive email updates',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadBookings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClientColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reporting no-show: $e'),
            backgroundColor: ClientColors.danger,
          ),
        );
      }
    }
  }
}
