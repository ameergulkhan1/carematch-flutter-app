import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../models/booking_model.dart';
import '../../../../services/enhanced_booking_service.dart';
import '../../../../core/constants/app_colors.dart';

class CalendarViewScreen extends StatefulWidget {
  final bool isCaregiver;

  const CalendarViewScreen({
    super.key,
    this.isCaregiver = false,
  });

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  final EnhancedBookingService _bookingService = EnhancedBookingService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<BookingModel> _allBookings = [];
  Map<DateTime, List<BookingModel>> _bookingsByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final bookingsStream = widget.isCaregiver
            ? _bookingService.getCaregiverBookings(user.uid)
            : _bookingService.getClientBookings(user.uid);

        bookingsStream.listen((bookings) {
          setState(() {
            _allBookings = bookings;
            _bookingsByDate = _groupBookingsByDate(bookings);
            _isLoading = false;
          });
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<DateTime, List<BookingModel>> _groupBookingsByDate(
      List<BookingModel> bookings) {
    final map = <DateTime, List<BookingModel>>{};
    for (final booking in bookings) {
      final date = DateTime(
        booking.startDate.year,
        booking.startDate.month,
        booking.startDate.day,
      );
      if (map[date] == null) {
        map[date] = [];
      }
      map[date]!.add(booking);
    }
    return map;
  }

  List<BookingModel> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _bookingsByDate[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar Widget
                Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 2,
                  child: TableCalendar(
                    firstDay:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Selected Date Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDay != null
                            ? DateFormat('EEEE, MMMM d, y')
                                .format(_selectedDay!)
                            : 'Select a date',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Bookings List for Selected Date
                Expanded(
                  child: _buildBookingsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildBookingsList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Select a date to view bookings'),
      );
    }

    final bookings = _getEventsForDay(_selectedDay!);

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookings on this date',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor = _getStatusColor(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetails(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isCaregiver
                              ? booking.clientName
                              : booking.caregiverName ?? 'Caregiver',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          booking.serviceType.name,
                          style: TextStyle(
                            fontSize: 14,
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Time Row
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.startTime ?? 'TBD'} - ${booking.endTime ?? 'TBD'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.hourglass_empty,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.totalHours} hrs',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              if (booking.specialRequirements?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.specialRequirements!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
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

                  // Title
                  Text(
                    'Booking Details',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(booking.status),
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  _buildDetailRow(
                      Icons.person,
                      'Name',
                      widget.isCaregiver
                          ? booking.clientName
                          : (booking.caregiverName ?? 'TBD')),
                  _buildDetailRow(
                      Icons.category, 'Service', booking.serviceType.name),
                  _buildDetailRow(Icons.calendar_today, 'Date',
                      DateFormat('EEEE, MMMM d, y').format(booking.startDate)),
                  _buildDetailRow(Icons.access_time, 'Time',
                      '${booking.startTime ?? 'TBD'} - ${booking.endTime ?? 'TBD'}'),
                  _buildDetailRow(Icons.hourglass_empty, 'Duration',
                      '${booking.totalHours} hours'),
                  _buildDetailRow(
                      Icons.attach_money, 'Rate', '\$${booking.hourlyRate}/hr'),
                  _buildDetailRow(Icons.price_check, 'Total',
                      '\$${booking.totalAmount.toStringAsFixed(2)}'),

                  if (booking.specialRequirements?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Special Requirements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(booking.specialRequirements!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.pendingPayment:
        return Colors.amber;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.pendingReschedule:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.pendingPayment:
        return 'Pending Payment';
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
      case BookingStatus.pendingReschedule:
        return 'Reschedule Requested';
      default:
        return status.name;
    }
  }
}
