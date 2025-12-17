import 'package:flutter/material.dart';
import '../caregiver_colors.dart';
import '../../../../../shared/utils/responsive_utils.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getContentPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildRatingOverview(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildReviewCard(
            'John Smith',
            5,
            'Excellent caregiver! Very professional and caring.',
            '2 days ago',
            isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildReviewCard(
            'Mary Johnson',
            5,
            'Highly recommend! My mother loves her visits.',
            '1 week ago',
            isMobile,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          _buildReviewCard(
            'Robert Williams',
            4,
            'Great service, always on time and very helpful.',
            '2 weeks ago',
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CaregiverColors.warning,
            CaregiverColors.warning.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CaregiverColors.warning.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '4.8',
            style: TextStyle(
              fontSize: isMobile ? 40 : 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star,
                color: Colors.white,
                size: isMobile ? 22 : 26,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on 48 reviews',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isMobile ? 13 : 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    String clientName,
    int rating,
    String review,
    String timeAgo,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: CaregiverColors.primary.withOpacity(0.1),
                child: Text(
                  clientName[0],
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
                      clientName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CaregiverColors.dark,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: CaregiverColors.warning,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
