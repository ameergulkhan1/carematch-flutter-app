import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../caregiver_colors.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAvailable = true;
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final data = doc.data();

        if (data != null && data['availability'] != null) {
          final availability = data['availability'] as Map<String, dynamic>;
          setState(() {
            for (int i = 0; i < _weekSchedule.length; i++) {
              final day = _weekSchedule[i]['day'];
              if (availability.containsKey(day)) {
                _weekSchedule[i] = {
                  'day': day,
                  'enabled': availability[day]['enabled'] ?? true,
                  'hours': availability[day]['hours'] ?? '9:00 AM - 5:00 PM',
                };
              }
            }
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('Error loading availability: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final availability = <String, dynamic>{};
        for (var day in _weekSchedule) {
          availability[day['day']] = {
            'enabled': day['enabled'],
            'hours': day['hours'],
          };
        }

        await _firestore.collection('users').doc(user.uid).update({
          'availability': availability,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Availability updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error saving availability: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error saving availability: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
          ..._weekSchedule
              .asMap()
              .entries
              .map((entry) => _buildDayCard(entry.key, entry.value)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveAvailability,
              icon: const Icon(Icons.save),
              label: const Text('Save Availability',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: CaregiverColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
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
            activeThumbColor: CaregiverColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int index, Map<String, dynamic> day) {
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
                    color:
                        isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              setState(() {
                _weekSchedule[index]['enabled'] = value;
                if (!value) {
                  _weekSchedule[index]['hours'] = 'Unavailable';
                } else {
                  _weekSchedule[index]['hours'] = '9:00 AM - 5:00 PM';
                }
              });
            },
            activeThumbColor: CaregiverColors.success,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: isEnabled ? () => _editTimeSlot(index) : null,
            color: CaregiverColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _editTimeSlot(int index) async {
    final TextEditingController controller = TextEditingController(
      text: _weekSchedule[index]['hours'],
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_weekSchedule[index]['day']} Hours'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., 9:00 AM - 5:00 PM',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _weekSchedule[index]['hours'] = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CaregiverColors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
