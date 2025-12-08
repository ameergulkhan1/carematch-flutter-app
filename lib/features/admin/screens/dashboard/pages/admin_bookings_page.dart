import 'package:flutter/material.dart';
import '../../../../../services/enhanced_booking_service.dart';
import '../../../../../models/booking_model.dart';
import '../admin_colors.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
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
      _bookingService.getAllBookings().listen((bookings) {
        if (mounted) {
          setState(() {
            _bookings = bookings;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading bookings: $e');
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
          _buildHeader(),
          const SizedBox(height: 24),
          _buildFilterChips(),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingsTable(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AdminColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage all platform bookings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _loadBookings(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Pending', 'Confirmed', 'In Progress', 'Completed', 'Disputed', 'Cancelled'];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
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
          selectedColor: AdminColors.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? AdminColors.primary : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? AdminColors.primary : Colors.grey.shade300,
          ),
        );
      }).toList(),
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
              'No bookings found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookings will appear here as they are created',
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

  Widget _buildBookingsTable() {
    List<BookingModel> filteredBookings = _bookings;

    if (_selectedFilter != 'All') {
      filteredBookings = _bookings.where((booking) {
        switch (_selectedFilter) {
          case 'Pending':
            return booking.status == BookingStatus.pending ||
                   booking.status == BookingStatus.pendingPayment;
          case 'Confirmed':
            return booking.status == BookingStatus.confirmed;
          case 'In Progress':
            return booking.status == BookingStatus.inProgress;
          case 'Completed':
            return booking.status == BookingStatus.completed;
          case 'Disputed':
            return booking.status == BookingStatus.disputed;
          case 'Cancelled':
            return booking.status == BookingStatus.cancelled ||
                   booking.status == BookingStatus.rejected;
          default:
            return true;
        }
      }).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: filteredBookings.map((booking) {
          return Column(
            children: [
              _buildBookingRow(booking),
              if (booking != filteredBookings.last)
                Divider(height: 1, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingRow(BookingModel booking) {
    final statusColor = _getStatusColor(booking.status);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.bookingRequestId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.clientName} → ${booking.caregiverName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              booking.serviceType.name.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '\$${booking.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.dark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 20),
            onPressed: () => _showBookingActions(booking),
          ),
        ],
      ),
    );
  }

  void _showBookingActions(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show booking details dialog
              },
            ),
            if (booking.status == BookingStatus.disputed)
              ListTile(
                leading: const Icon(Icons.gavel, color: AdminColors.warning),
                title: const Text('Resolve Dispute'),
                onTap: () {
                  Navigator.pop(context);
                  _showResolveDisputeDialog(booking);
                },
              ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export booking data
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveDisputeDialog(BookingModel booking) {
    final refundController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: refundController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              final refund = double.tryParse(refundController.text) ?? 0;
              final notes = notesController.text;
              // TODO: Call _bookingService.resolveDispute(booking.id, 'admin_id', notes, refund);
              print('Admin notes: $notes, Refund: \$$refund');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dispute resolved with \$${refund.toStringAsFixed(2)} refund')),
              );
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingPayment:
      case BookingStatus.pendingReschedule:
        return AdminColors.warning;
      case BookingStatus.confirmed:
        return AdminColors.success;
      case BookingStatus.inProgress:
        return AdminColors.info;
      case BookingStatus.completed:
        return AdminColors.success;
      case BookingStatus.disputed:
        return AdminColors.danger;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
      case BookingStatus.resolved:
        return Colors.grey;
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
