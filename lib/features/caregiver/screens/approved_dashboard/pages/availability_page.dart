import 'package:flutter/material.dart';
import '../caregiver_colors.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  bool _isAvailable = true;

  final List<Map<String, dynamic>> _weekSchedule = [
    {'day': 'Monday', 'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
    {'day': 'Tuesday', 'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
    {'day': 'Wednesday', 'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
    {'day': 'Thursday', 'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
    {'day': 'Friday', 'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
    {'day': 'Saturday', 'enabled': false, 'hours': 'Unavailable'},
    {'day': 'Sunday', 'enabled': false, 'hours': 'Unavailable'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvailabilityToggle(),
          const SizedBox(height: 24),
          const Text(
            'Weekly Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CaregiverColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          ..._weekSchedule.map(_buildDayCard),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Availability Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CaregiverColors.dark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Toggle your availability for new bookings',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          Switch(
            value: _isAvailable,
            onChanged: (value) {
              setState(() {
                _isAvailable = value;
              });
            },
            activeColor: CaregiverColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final isEnabled = day['enabled'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? CaregiverColors.primary.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEnabled
                  ? CaregiverColors.primary.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day['day'][0],
                style: TextStyle(
                  color: isEnabled ? CaregiverColors.primary : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day['day'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CaregiverColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day['hours'],
                  style: TextStyle(
                    fontSize: 13,
                    color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              // TODO: Edit time slot
            },
            color: CaregiverColors.primary,
          ),
        ],
      ),
    );
  }
}
