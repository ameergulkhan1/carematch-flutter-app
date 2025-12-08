import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/caregiver_user_model.dart';
import '../../../services/caregiver_search_service.dart';
import '../../../providers/auth_provider.dart';
import 'booking_request_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/screens/chat_conversation_screen.dart';

class CaregiverProfileView extends StatefulWidget {
  final CaregiverUser caregiver;

  const CaregiverProfileView({super.key, required this.caregiver});

  @override
  State<CaregiverProfileView> createState() => _CaregiverProfileViewState();
}

class _CaregiverProfileViewState extends State<CaregiverProfileView> {
  final CaregiverSearchService _searchService = CaregiverSearchService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;
    
    if (userId != null) {
      final isFav = await _searchService.isCaregiverFavorited(userId, widget.caregiver.uid);
      setState(() {
        _isFavorite = isFav;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save favorites')),
      );
      return;
    }

    if (_isFavorite) {
      await _searchService.removeCaregiverFromFavorites(userId, widget.caregiver.uid);
    } else {
      await _searchService.saveCaregiverToFavorites(userId, widget.caregiver.uid);
    }
    
    setState(() => _isFavorite = !_isFavorite);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final experience = int.tryParse(widget.caregiver.yearsOfExperience ?? '0') ?? 0;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(experience),
                  const SizedBox(height: 24),
                  _buildQuickStats(experience),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                  _buildSpecializationsSection(),
                  const SizedBox(height: 24),
                  _buildCertificationsSection(),
                  const SizedBox(height: 24),
                  _buildAvailabilitySection(),
                  const SizedBox(height: 24),
                  _buildContactSection(),
                  const SizedBox(height: 32),
                  _buildBookNowButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      actions: [
        if (!_isLoading)
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon')),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: Text(
                widget.caregiver.fullName[0].toUpperCase(),
                style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(int experience) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.caregiver.fullName,
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.caregiver.city}, ${widget.caregiver.state}',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.caregiver.verificationStatus == 'approved'
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.caregiver.verificationStatus == 'approved'
                            ? Icons.verified
                            : Icons.pending,
                        size: 18,
                        color: widget.caregiver.verificationStatus == 'approved'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.caregiver.verificationStatus == 'approved'
                            ? 'Verified'
                            : 'Pending Verification',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: widget.caregiver.verificationStatus == 'approved'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(widget.caregiver.email, style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(widget.caregiver.phoneNumber, style: AppTextStyles.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(int experience) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.work_outline,
            label: 'Experience',
            value: '$experience years',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.verified_user,
            label: 'Background',
            value: widget.caregiver.documentsSubmitted ? 'Verified' : 'Pending',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Member Since',
            value: '${widget.caregiver.createdAt.year}',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('About', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.caregiver.bio ?? 'No bio provided yet.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecializationsSection() {
    if (widget.caregiver.specializations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Specializations', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.caregiver.specializations.map((spec) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        spec,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationsSection() {
    if (widget.caregiver.certifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Certifications', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.caregiver.certifications.map((cert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 20, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(cert, style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final availability = widget.caregiver.availability;
    
    // Default availability if not set
    final defaultAvailability = {
      'Monday': {'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
      'Tuesday': {'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
      'Wednesday': {'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
      'Thursday': {'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
      'Friday': {'enabled': true, 'hours': '9:00 AM - 5:00 PM'},
      'Saturday': {'enabled': false, 'hours': 'Unavailable'},
      'Sunday': {'enabled': false, 'hours': 'Unavailable'},
    };
    
    final schedule = availability ?? defaultAvailability;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Availability Schedule', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ...schedule.entries.map((entry) {
              final day = entry.key;
              final dayData = entry.value as Map<String, dynamic>;
              final enabled = dayData['enabled'] as bool? ?? false;
              final hours = dayData['hours'] as String? ?? 'Not set';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.success.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: enabled
                        ? AppColors.success.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: enabled
                            ? AppColors.success.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 1),
                          style: TextStyle(
                            color: enabled ? AppColors.success : Colors.grey,
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
                            day,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                enabled ? Icons.check_circle : Icons.cancel,
                                size: 14,
                                color: enabled ? AppColors.success : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hours,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: enabled
                                      ? AppColors.textSecondary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Contact Information', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildContactRow(Icons.location_on, 'Address', widget.caregiver.address),
            const SizedBox(height: 12),
            _buildContactRow(
              Icons.location_city,
              'Location',
              '${widget.caregiver.city}, ${widget.caregiver.state} ${widget.caregiver.zipCode}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookNowButton() {
    return Column(
      children: [
        // Chat button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () async {
              final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                // Get current user's name
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .get();
                
                final userName = userDoc.data()?['fullName'] ?? 'Client';
                final userImage = userDoc.data()?['profileImage'];
                
                // Create or get chat
                final chatService = ChatService();
                final chatId = await chatService.createOrGetChat(
                  userId1: currentUser.uid,
                  userId2: widget.caregiver.uid,
                  user1Name: userName,
                  user2Name: widget.caregiver.fullName,
                  user1Image: userImage,
                  user2Image: null, // CaregiverUser doesn't have profileImage field
                );
                
                // Navigate to chat
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatConversationScreen(
                        chatId: chatId,
                        otherUserName: widget.caregiver.fullName,
                        otherUserImage: null,
                      ),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(
              'Chat with ${widget.caregiver.fullName.split(' ')[0]}',
              style: AppTextStyles.buttonLarge,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Book now button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: widget.caregiver.verificationStatus == 'approved'
                ? () {
                    // Navigate to booking request screen (Stage 1-2)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookingRequestScreen(caregiver: widget.caregiver),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.calendar_month),
            label: Text(
              widget.caregiver.verificationStatus == 'approved'
                  ? 'Book Now'
                  : 'Verification Pending',
              style: AppTextStyles.buttonLarge,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}
