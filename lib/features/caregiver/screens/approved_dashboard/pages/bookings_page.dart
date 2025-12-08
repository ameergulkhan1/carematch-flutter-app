import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../caregiver_colors.dart';
import '../../../../../services/enhanced_booking_service.dart';
import '../../../../../models/booking_model.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  final EnhancedBookingService _bookingService = EnhancedBookingService();
  String _selectedFilter = 'All';
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🔵 Loading bookings for caregiver: ${user.uid}');
        _bookingService.getCaregiverBookings(user.uid).listen(
          (bookings) {
            print('✅ Loaded ${bookings.length} bookings');
            if (mounted) {
              setState(() {
                _bookings = bookings;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            print('❌ Error in bookings stream: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading bookings: $error')),
              );
            }
          },
        );
      } else {
        print('❌ No user logged in');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading bookings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'All'
                  ? 'No bookings yet'
                  : 'No $_selectedFilter bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'All'
                  ? 'Your bookings will appear here once clients book your services'
                  : 'Try selecting a different filter',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Upcoming', 'Completed', 'Cancelled'];

    return Wrap(
      spacing: 12,
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return FilterChip(
          label: Text(filter),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = filter;
            });
          },
          backgroundColor: Colors.white,
          selectedColor: CaregiverColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? CaregiverColors.primary : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? CaregiverColors.primary : Colors.grey.shade300,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingsList() {
    List<BookingModel> filteredBookings = _bookings;

    if (_selectedFilter != 'All') {
      filteredBookings = _bookings.where((booking) {
        switch (_selectedFilter) {
          case 'Upcoming':
            return booking.status == BookingStatus.confirmed ||
                booking.status == BookingStatus.pendingPayment;
          case 'Completed':
            return booking.status == BookingStatus.completed;
          case 'Cancelled':
            return booking.status == BookingStatus.cancelled ||
                booking.status == BookingStatus.rejected;
          default:
            return true;
        }
      }).toList();
    }

    return Column(
      children: filteredBookings.map((booking) {
        return Column(
          children: [
            _buildBookingCard(booking),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _getBookingStatusColor(booking.status);

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
              CircleAvatar(
                backgroundColor: CaregiverColors.primary.withOpacity(0.1),
                child: Text(
                  booking.clientName[0].toUpperCase(),
                  style: const TextStyle(
                    color: CaregiverColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CaregiverColors.dark,
                      ),
                    ),
                    Text(
                      booking.serviceType.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 24),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${booking.startTime} - ${booking.endTime}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (booking.clientAddress != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${booking.clientAddress!['address'] ?? ''}, ${booking.clientAddress!['city'] ?? ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
          if (booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showRejectDialog(context, booking);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CaregiverColors.danger,
                      side: const BorderSide(color: CaregiverColors.danger, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        print('🔵 User accepting booking: ${booking.id}');
                        final success =
                            await _bookingService.acceptBookingRequest(
                          booking.id,
                          user.uid,
                        );

                        // Close loading dialog
                        if (mounted) Navigator.pop(context);

                        if (success) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '✅ Booking accepted! Awaiting client payment.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          _loadBookings();
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Failed to accept booking. Please check the logs or try again.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('❌ You must be logged in to accept bookings'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CaregiverColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (booking.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showBookingDetails(context, booking);
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CaregiverColors.primary,
                      side: const BorderSide(color: CaregiverColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Start session
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await _bookingService.startSession(
                            booking.id, user.uid);
                        _loadBookings();
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Session', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CaregiverColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (booking.status == BookingStatus.pendingPayment ||
              booking.status == BookingStatus.inProgress ||
              booking.status == BookingStatus.completed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showBookingDetails(context, booking);
                },
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('View Full Details', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CaregiverColors.primary,
                  side: const BorderSide(color: CaregiverColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (booking.status == BookingStatus.inProgress) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // End session
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await _bookingService.endSession(booking.id, user.uid);
                    _loadBookings();
                  }
                },
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('End Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CaregiverColors.danger,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBookingStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingPayment:
      case BookingStatus.pendingReschedule:
        return CaregiverColors.warning;
      case BookingStatus.confirmed:
        return CaregiverColors.secondary;
      case BookingStatus.inProgress:
        return CaregiverColors.primary;
      case BookingStatus.completed:
        return CaregiverColors.secondary;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
      case BookingStatus.disputed:
      case BookingStatus.resolved:
        return CaregiverColors.danger;
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

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CaregiverColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        color: CaregiverColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: CaregiverColors.dark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${booking.id.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 24),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        _getBookingStatusColor(booking.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getBookingStatusColor(booking.status),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(booking.status),
                        size: 18,
                        color: _getBookingStatusColor(booking.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(booking.status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getBookingStatusColor(booking.status),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Client Information
                _buildDetailSection(
                  'Client Information',
                  Icons.person,
                  [
                    _buildDetailRow('Name', booking.clientName),
                  ],
                ),
                const SizedBox(height: 20),

                // Service Details
                _buildDetailSection(
                  'Service Details',
                  Icons.medical_services,
                  [
                    _buildDetailRow(
                        'Type', booking.serviceType.name.toUpperCase()),
                    _buildDetailRow('Date',
                        '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}'),
                    _buildDetailRow(
                        'Time', '${booking.startTime} - ${booking.endTime}'),
                  ],
                ),
                const SizedBox(height: 20),

                // Location
                if (booking.clientAddress != null) ...[
                  _buildDetailSection(
                    'Service Location',
                    Icons.location_on,
                    [
                      _buildDetailRow('Address',
                          booking.clientAddress!['address'] ?? 'N/A'),
                      _buildDetailRow(
                          'City', booking.clientAddress!['city'] ?? 'N/A'),
                      _buildDetailRow(
                          'State', booking.clientAddress!['state'] ?? 'N/A'),
                      _buildDetailRow('Zip Code',
                          booking.clientAddress!['zipCode'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Payment Information
                _buildDetailSection(
                  'Payment Information',
                  Icons.payment,
                  [
                    _buildDetailRow(
                        'Amount', '\$${booking.totalAmount.toStringAsFixed(2)}',
                        isHighlighted: true),
                    if (booking.paymentMethod != null)
                      _buildDetailRow('Method', booking.paymentMethod!),
                    if (booking.paymentId != null)
                      _buildDetailRow('Transaction ID', booking.paymentId!),
                  ],
                ),
                const SizedBox(height: 20),

                // Special Instructions - Coming soon
                // (Field will be added to BookingModel in future update)

                // Timestamps
                _buildDetailSection(
                  'Booking Timeline',
                  Icons.access_time,
                  [
                    _buildDetailRow(
                      'Created',
                      '${booking.createdAt.day}/${booking.createdAt.month}/${booking.createdAt.year} ${booking.createdAt.hour}:${booking.createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                if (booking.status == BookingStatus.confirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final location = booking.clientAddress != null
                              ? '${booking.clientAddress!['address'] ?? ''}, ${booking.clientAddress!['city'] ?? ''}'
                              : '';
                          await _bookingService.startSession(
                              booking.id, location);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadBookings();
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CaregiverColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                if (booking.status == BookingStatus.inProgress) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await _bookingService.endSession(
                              booking.id, user.uid);
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadBookings();
                          }
                        }
                      },
                      icon: const Icon(Icons.stop),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CaregiverColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, BookingModel booking) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejecting this booking:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., Schedule conflict, Not available...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.pop(context); // Close dialog

                final success = await _bookingService.rejectBookingRequest(
                  booking.id,
                  user.uid,
                  reasonController.text.trim(),
                );

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking rejected'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Failed to reject booking'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                _loadBookings();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CaregiverColors.danger,
            ),
            child: const Text('Reject Booking'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: CaregiverColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CaregiverColors.dark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted
                    ? CaregiverColors.primary
                    : CaregiverColors.dark,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingPayment:
      case BookingStatus.pendingReschedule:
        return Icons.hourglass_empty;
      case BookingStatus.confirmed:
        return Icons.check_circle_outline;
      case BookingStatus.inProgress:
        return Icons.play_circle_outline;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return Icons.cancel_outlined;
      case BookingStatus.disputed:
        return Icons.warning_outlined;
      case BookingStatus.resolved:
        return Icons.verified_outlined;
    }
  }
}
