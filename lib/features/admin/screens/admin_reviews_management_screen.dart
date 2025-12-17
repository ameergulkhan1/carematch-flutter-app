import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/review_model.dart';
import '../../../services/review_service.dart';

/// Admin screen for managing and moderating ratings/reviews
class AdminReviewsManagementScreen extends StatefulWidget {
  const AdminReviewsManagementScreen({super.key});

  @override
  State<AdminReviewsManagementScreen> createState() => _AdminReviewsManagementScreenState();
}

class _AdminReviewsManagementScreenState extends State<AdminReviewsManagementScreen> {
  final ReviewService _reviewService = ReviewService();
  String _selectedFilter = 'all'; // all, flagged, pending, approved
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewService.getAllReviews().listen((reviews) {
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    }, onError: (error) {
      print('Error loading reviews: $error');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  List<Review> get _filteredReviews {
    switch (_selectedFilter) {
      case 'flagged':
        return _reviews.where((r) => r.isFlagged).toList();
      case 'pending':
        return _reviews.where((r) => !r.isVisible).toList();
      case 'approved':
        return _reviews.where((r) => r.isVisible && !r.isFlagged).toList();
      default:
        return _reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Reviews Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _loadReviews(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),
          
          // Filter Tabs
          _buildFilterTabs(),
          
          // Reviews List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReviews.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredReviews.length,
                        itemBuilder: (context, index) {
                          return _buildReviewCard(_filteredReviews[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final totalReviews = _reviews.length;
    final flaggedCount = _reviews.where((r) => r.isFlagged).length;
    final averageRating = totalReviews > 0
        ? _reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews
        : 0.0;
    final pendingCount = _reviews.where((r) => !r.isVisible).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Reviews Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', totalReviews.toString(), Icons.reviews),
              _buildStatItem('Avg Rating', averageRating.toStringAsFixed(1), Icons.star),
              _buildStatItem('Flagged', flaggedCount.toString(), Icons.flag),
              _buildStatItem('Pending', pendingCount.toString(), Icons.pending),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all', _reviews.length),
          const SizedBox(width: 12),
          _buildFilterChip('Flagged', 'flagged', 
            _reviews.where((r) => r.isFlagged).length),
          const SizedBox(width: 12),
          _buildFilterChip('Pending', 'pending',
            _reviews.where((r) => !r.isVisible).length),
          const SizedBox(width: 12),
          _buildFilterChip('Approved', 'approved',
            _reviews.where((r) => r.isVisible && !r.isFlagged).length),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text('$label ($count)'),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with reviewer info and rating
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    review.reviewerName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.reviewerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: review.reviewerType == 'client'
                                  ? Colors.blue.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              review.reviewerType == 'client' ? 'Client' : 'Caregiver',
                              style: TextStyle(
                                fontSize: 11,
                                color: review.reviewerType == 'client'
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rating for: ${review.revieweeName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRatingStars(review.rating),
              ],
            ),
            const SizedBox(height: 12),

            // Review comment
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),

            // Detailed ratings
            if (review.detailedRatings != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: review.detailedRatings!.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatRatingKey(entry.key),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Photos
            if (review.photos.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Status badges
            Row(
              children: [
                if (review.isFlagged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Flagged',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                if (!review.isVisible)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Hidden',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Admin actions
            Row(
              children: [
                if (review.isFlagged && review.isVisible)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _hideReview(review),
                      icon: const Icon(Icons.visibility_off, size: 16),
                      label: const Text('Hide'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                if (!review.isVisible)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _approveReview(review),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Approve'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (review.isFlagged)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _unflagReview(review),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Unflag'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReviewDetails(review),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: 18,
            color: Colors.amber,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatRatingKey(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _hideReview(Review review) async {
    try {
      await _reviewService.hideReview(review.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review hidden successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error hiding review: $e')),
      );
    }
  }

  Future<void> _approveReview(Review review) async {
    try {
      await _reviewService.approveReview(review.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // No need to call _loadReviews() as it's using a stream
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving review: $e')),
      );
    }
  }

  Future<void> _unflagReview(Review review) async {
    try {
      await _reviewService.unflagReview(review.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review unflagged successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // No need to call _loadReviews() as it's using a stream
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unflagging review: $e')),
      );
    }
  }

  void _showReviewDetails(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', review.bookingId),
              _buildDetailRow('Reviewer', review.reviewerName),
              _buildDetailRow('Reviewee', review.revieweeName),
              _buildDetailRow('Type', review.reviewerType),
              _buildDetailRow('Rating', review.rating.toString()),
              _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(review.createdAt)),
              if (review.isFlagged) ...[
                const Divider(),
                _buildDetailRow('Flagged', 'Yes'),
                if (review.flagReason != null)
                  _buildDetailRow('Flag Reason', review.flagReason!),
              ],
              if (review.moderationNotes != null) ...[
                const Divider(),
                _buildDetailRow('Moderation Notes', review.moderationNotes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
