import 'package:flutter/material.dart';
import '../caregiver_colors.dart';

class ProfilePage extends StatelessWidget {
  final Map<String, dynamic>? caregiverData;

  const ProfilePage({super.key, this.caregiverData});

  @override
  Widget build(BuildContext context) {
    final name = caregiverData?['fullName'] ?? 'Caregiver';
    final email = caregiverData?['email'] ?? '';
    final phone = caregiverData?['phoneNumber'] ?? '';
    final specializations =
        caregiverData?['specializations'] as List<dynamic>? ?? [];
    final bio = caregiverData?['bio'] ?? 'No bio available';
    final experience = caregiverData?['yearsOfExperience'] ?? 'Not specified';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildProfileHeader(name, experience.toString()),
          const SizedBox(height: 24),
          _buildPersonalInfo(email, phone),
          const SizedBox(height: 24),
          _buildSpecializations(specializations),
          const SizedBox(height: 24),
          _buildBio(bio),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String experience) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: CaregiverColors.primary,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CaregiverColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: CaregiverColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: CaregiverColors.secondary, size: 16),
                SizedBox(width: 6),
                Text(
                  'Verified Professional',
                  style: TextStyle(
                    color: CaregiverColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
              onPressed: () {
                // TODO: Edit profile
              },
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

  Widget _buildPersonalInfo(String email, String phone) {
    final items = [
      {'icon': Icons.email, 'label': 'Email', 'value': email},
      {'icon': Icons.phone, 'label': 'Phone', 'value': phone},
      {'icon': Icons.cake, 'label': 'Date of Birth', 'value': 'Jan 15, 1990'},
      {
        'icon': Icons.location_on,
        'label': 'Address',
        'value': '123 Main St, Boston, MA'
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

  Widget _buildSpecializations(List<dynamic> specializations) {
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

  Widget _buildBio(String bio) {
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
