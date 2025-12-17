import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import 'dashboard/client_colors.dart';

class ClientReviewsScreen extends StatefulWidget {
  const ClientReviewsScreen({super.key});

  @override
  State<ClientReviewsScreen> createState() => _ClientReviewsScreenState();
}

class _ClientReviewsScreenState extends State<ClientReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all'; // all, visible, hidden, flagged

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: Column(
        children: [
          // Header with stats and filters
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Reviews',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ClientColors.dark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'All reviews you\'ve submitted for caregivers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Reviews', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Visible', 'visible'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hidden', 'hidden'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Flagged', 'flagged'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reviews list
          Expanded(
            child: userId == null
                ? const Center(child: Text('Please login to view reviews'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _getReviewsStream(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final reviews = snapshot.data?.docs ?? [];

                      if (reviews.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filterStatus == 'all'
                                    ? 'No reviews yet'
                                    : 'No ${_filterStatus} reviews',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete a booking to leave a review',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review =
                              reviews[index].data() as Map<String, dynamic>;
                          final reviewId = reviews[index].id;
                          return _buildReviewCard(review, reviewId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getReviewsStream(String userId) {
    Query query = _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    switch (_filterStatus) {
      case 'visible':
        query = query.where('isVisible', isEqualTo: true);
        break;
      case 'hidden':
        query = query.where('isVisible', isEqualTo: false);
        break;
      case 'flagged':
        query = query.where('isFlagged', isEqualTo: true);
        break;
    }

    return query.snapshots();
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      backgroundColor: Colors.white,
      selectedColor: ClientColors.primary.withOpacity(0.1),
      checkmarkColor: ClientColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? ClientColors.primary : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? ClientColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, String reviewId) {
    final overallRating = (review['overallRating'] ?? 0).toDouble();
    final comment = review['comment'] ?? '';
    final caregiverName = review['revieweeName'] ?? 'Unknown';
    final createdAt = (review['createdAt'] as Timestamp?)?.toDate();
    final isVisible = review['isVisible'] ?? true;
    final isFlagged = review['isFlagged'] ?? false;
    final detailedRatings = review['detailedRatings'] as Map<String, dynamic>?;
    final photos = (review['photoUrls'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFlagged
              ? ClientColors.danger.withOpacity(0.3)
              : Colors.grey.shade200,
          width: isFlagged ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: ClientColors.primary.withOpacity(0.1),
                  child: Text(
                    caregiverName[0].toUpperCase(),
                    style: const TextStyle(
                      color: ClientColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caregiverName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ClientColors.dark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAt != null
                            ? DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(createdAt)
                            : 'Unknown date',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isFlagged)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ClientColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag,
                                size: 12, color: ClientColors.danger),
                            SizedBox(width: 4),
                            Text(
                              'Flagged',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: ClientColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isVisible) ...[
                      if (isFlagged) const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_off,
                                size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Hidden',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Rating and comment
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall rating
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < overallRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 24,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      overallRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.dark,
                      ),
                    ),
                  ],
                ),

                // Detailed ratings
                if (detailedRatings != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildDetailRating('Professionalism',
                          detailedRatings['professionalism']),
                      _buildDetailRating(
                          'Punctuality', detailedRatings['punctuality']),
                      _buildDetailRating(
                          'Care Quality', detailedRatings['careQuality']),
                      _buildDetailRating(
                          'Communication', detailedRatings['communication']),
                    ],
                  ),
                ],

                // Comment
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],

                // Photos
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(photos[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRating(String label, dynamic value) {
    final rating = (value ?? 0).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ClientColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClientColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
