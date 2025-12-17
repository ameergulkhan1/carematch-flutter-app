import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../caregiver_colors.dart';
import '../../../../../shared/utils/responsive_utils.dart';
import '../../../../../models/caregiver_user_model.dart';
import 'edit_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? caregiverData;
  final String? userId;

  const ProfilePage({super.key, this.caregiverData, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _currentData;

  @override
  void initState() {
    super.initState();
    _currentData = widget.caregiverData;
  }

  Future<void> _refreshProfile() async {
    if (widget.userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
        
        if (doc.exists && mounted) {
          setState(() {
            _currentData = doc.data();
          });
        }
      } catch (e) {
        print('Error refreshing profile: $e');
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (widget.userId == null || _currentData == null) return;

    try {
      // Create CaregiverUser from current data
      final caregiverUser = CaregiverUser.fromFirestore(
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(caregiverUser: caregiverUser),
        ),
      );

      // Refresh if changes were saved
      if (result == true) {
        _refreshProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getContentPadding(context);
    final name = _currentData?['fullName'] ?? 'Caregiver';
    final email = _currentData?['email'] ?? '';
    final phone = _currentData?['phoneNumber'] ?? '';
    final address = _currentData?['address'] ?? '123 Main St';
    final city = _currentData?['city'] ?? 'Boston';
    final state = _currentData?['state'] ?? 'MA';
    final latitude = _currentData?['latitude'];
    final longitude = _currentData?['longitude'];
    final specializations =
        _currentData?['specializations'] as List<dynamic>? ?? [];
    final bio = _currentData?['bio'] ?? 'No bio available';
    final experience = _currentData?['yearsOfExperience'] ?? 'Not specified';

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildProfileHeader(name, experience.toString(), isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildPersonalInfo(email, phone, address, city, state, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildLocationInfo(latitude, longitude, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildSpecializations(specializations, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildBio(bio, isMobile),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String experience, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CaregiverColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CaregiverColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CaregiverColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isMobile ? 45 : 55,
              backgroundColor: CaregiverColors.primary,
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: isMobile ? 32 : 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            name,
            style: TextStyle(
              fontSize: isMobile ? 20 : 26,
              fontWeight: FontWeight.bold,
              color: CaregiverColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CaregiverColors.primary.withOpacity(0.2),
                  CaregiverColors.primaryLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CaregiverColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: CaregiverColors.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'Verified Professional',
                  style: TextStyle(
                    color: CaregiverColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('24', 'Bookings'),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              _buildStatColumn('4.8', 'Rating'),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 24),
              ),
              _buildStatColumn(experience, 'Experience'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToEditProfile,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CaregiverColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CaregiverColors.dark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(String email, String phone, String address, 
      String city, String state, bool isMobile) {
    final items = [
      {'icon': Icons.email, 'label': 'Email', 'value': email},
      {'icon': Icons.phone, 'label': 'Phone', 'value': phone},
      {
        'icon': Icons.home,
        'label': 'Address',
        'value': address
      },
      {
        'icon': Icons.location_city,
        'label': 'City, State',
        'value': '$city, $state'
      },
    ];

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
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CaregiverColors.dark,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CaregiverColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: CaregiverColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['value'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CaregiverColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(double? latitude, double? longitude, bool isMobile) {
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
              const Text(
                'Map Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CaregiverColors.dark,
                ),
              ),
              const Spacer(),
              if (latitude != null && longitude != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: CaregiverColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, 
                          color: CaregiverColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Visible to clients',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CaregiverColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (latitude != null && longitude != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CaregiverColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CaregiverColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CaregiverColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: CaregiverColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your location is set',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CaregiverColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${latitude.toStringAsFixed(6)}\nLng: ${longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Location not set. Add your location to appear on the map for clients.',
                      style: TextStyle(
                        fontSize: 13,
                        color: CaregiverColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecializations(List<dynamic> specializations, bool isMobile) {
    final specs = specializations.isEmpty
        ? ['Elderly Care', 'Companionship', 'Post-Surgery Care']
        : specializations;

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
          const Text(
            'Specializations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CaregiverColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specs.map((spec) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: CaregiverColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CaregiverColors.accent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  spec.toString(),
                  style: const TextStyle(
                    color: CaregiverColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(String bio, bool isMobile) {
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
          const Text(
            'Professional Bio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CaregiverColors.dark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
