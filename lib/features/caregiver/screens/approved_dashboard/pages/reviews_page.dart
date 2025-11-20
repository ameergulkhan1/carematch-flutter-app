import 'package:flutter/material.dart';
import '../caregiver_colors.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildRatingOverview(),
          const SizedBox(height: 24),
          _buildReviewCard(
            'John Smith',
            5,
            'Excellent caregiver! Very professional and caring.',
            '2 days ago',
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'Mary Johnson',
            5,
            'Highly recommend! My mother loves her visits.',
            '1 week ago',
          ),
          const SizedBox(height: 16),
          _buildReviewCard(
            'Robert Williams',
            4,
            'Great service, always on time and very helpful.',
            '2 weeks ago',
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CaregiverColors.warning, Color(0xFFFBBF24)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            '4.8',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Based on 48 reviews',
            style: TextStyle(color: Colors.white, fontSize: 14),
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
  ) {
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
