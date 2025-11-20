import 'package:flutter/material.dart';
import '../caregiver_colors.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          const SizedBox(height: 24),
          _buildBookingsList(),
        ],
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
    final bookings = [
      {
        'client': 'John Smith',
        'service': 'Personal Care',
        'date': 'Nov 18, 2025',
        'time': '10:00 AM - 12:00 PM',
        'address': '123 Main St, Boston, MA',
        'status': 'Completed',
      },
      {
        'client': 'Mary Johnson',
        'service': 'Companionship',
        'date': 'Nov 20, 2025',
        'time': '2:00 PM - 4:00 PM',
        'address': '456 Oak Ave, Boston, MA',
        'status': 'Upcoming',
      },
      {
        'client': 'Robert Williams',
        'service': 'Meal Preparation',
        'date': 'Nov 20, 2025',
        'time': '4:30 PM - 6:30 PM',
        'address': '789 Pine Rd, Boston, MA',
        'status': 'Upcoming',
      },
    ];

    return Column(
      children: bookings.map((booking) {
        return Column(
          children: [
            _buildBookingCard(booking),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard(Map<String, String> booking) {
    final status = booking['status']!;
    final statusColor = CaregiverColors.getStatusColor(status);

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
                  booking['client']![0],
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
                      booking['client']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CaregiverColors.dark,
                      ),
                    ),
                    Text(
                      booking['service']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
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
              Icon(Icons.calendar_today,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                booking['date']!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 24),
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                booking['time']!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  booking['address']!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          if (status == 'Upcoming') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CaregiverColors.primary,
                      side: const BorderSide(color: CaregiverColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CaregiverColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
