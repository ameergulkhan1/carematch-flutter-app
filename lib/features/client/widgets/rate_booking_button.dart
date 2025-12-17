import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/booking_model.dart';
import '../../shared/screens/reviews/submit_review_screen.dart';

class RateBookingButton extends StatelessWidget {
  final BookingModel booking;
  final bool hasReview;
  final VoidCallback? onRated;

  const RateBookingButton({
    super.key,
    required this.booking,
    this.hasReview = false,
    this.onRated,
  });

  @override
  Widget build(BuildContext context) {
    if (hasReview) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 16),
            SizedBox(width: 6),
            Text(
              'Reviewed',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubmitReviewScreen(booking: booking),
          ),
        );

        if (result == true && onRated != null) {
          onRated!();
        }
      },
      icon: const Icon(Icons.star, size: 18),
      label: const Text('Rate & Review'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
