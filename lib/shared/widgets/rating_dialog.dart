import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Professional rating dialog with detailed ratings, photos, and proper flow
class RatingDialog extends StatefulWidget {
  final BookingModel booking;
  final String reviewerType; // 'client' or 'caregiver'
  final VoidCallback? onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.booking,
    required this.reviewerType,
    this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final ReviewService _reviewService = ReviewService();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  double _overallRating = 0.0;
  final Map<String, double> _detailedRatings = {
    'professionalism': 5.0,
    'punctuality': 5.0,
    'careQuality': 5.0,
    'communication': 5.0,
  };
  List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(
            images.take(5 - _selectedPhotos.length).map((xFile) => File(xFile.path)),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitRating() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an overall rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload photos
      List<String> photoUrls = [];
      for (var photo in _selectedPhotos) {
        final url = await _reviewService.uploadReviewPhoto(
          file: photo,
          reviewerId: currentUser.uid,
        );
        if (url != null) photoUrls.add(url);
      }

      // Determine reviewer and reviewee based on reviewerType
      final String reviewerId;
      final String reviewerName;
      final String revieweeId;
      final String revieweeName;

      if (widget.reviewerType == 'client') {
        reviewerId = widget.booking.clientId;
        reviewerName = widget.booking.clientName;
        revieweeId = widget.booking.caregiverId;
        revieweeName = widget.booking.caregiverName;
      } else {
        reviewerId = widget.booking.caregiverId;
        reviewerName = widget.booking.caregiverName;
        revieweeId = widget.booking.clientId;
        revieweeName = widget.booking.clientName;
      }

      // Create review
      final review = Review(
        id: '',
        bookingId: widget.booking.id,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        revieweeId: revieweeId,
        revieweeName: revieweeName,
        reviewerType: widget.reviewerType,
        rating: _overallRating,
        comment: _commentController.text.trim(),
        detailedRatings: _detailedRatings,
        photos: photoUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerifiedBooking: true,
      );

      final reviewId = await _reviewService.createReviewWithModeration(review: review);

      if (reviewId != null && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thank you for your ${_getRatingLabel(_overallRating.round())} rating!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        widget.onRatingSubmitted?.call();
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final String revieweeName = widget.reviewerType == 'client' 
        ? widget.booking.caregiverName 
        : widget.booking.clientName;
    final String revieweeRole = widget.reviewerType == 'client' ? 'Caregiver' : 'Client';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? screenSize.width * 0.95 : 600,
          maxHeight: screenSize.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          revieweeName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rate Your Experience',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              revieweeName,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              revieweeRole,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  shrinkWrap: true,
                  children: [
                    // Overall Rating
                    _buildOverallRating(isSmallScreen),
                    const SizedBox(height: 32),

                    // Detailed Ratings
                    _buildDetailedRatings(),
                    const SizedBox(height: 24),

                    // Comment
                    _buildCommentField(),
                    const SizedBox(height: 24),

                    // Photo Upload
                    _buildPhotoSection(),
                    const SizedBox(height: 32),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating(bool isSmallScreen) {
    return Column(
      children: [
        const Text(
          'Overall Rating',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => setState(() => _overallRating = (index + 1).toDouble()),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                child: Icon(
                  index < _overallRating ? Icons.star : Icons.star_border,
                  color: index < _overallRating ? Colors.amber : Colors.grey.shade400,
                  size: isSmallScreen ? 36 : 48,
                ),
              ),
            );
          }),
        ),
        if (_overallRating > 0) ...[
          const SizedBox(height: 12),
          Text(
            _getRatingLabel(_overallRating.round()),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Ratings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildRatingSlider(
          'Professionalism',
          'professionalism',
          Icons.work_outline,
        ),
        const SizedBox(height: 16),
        _buildRatingSlider(
          'Punctuality',
          'punctuality',
          Icons.access_time,
        ),
        const SizedBox(height: 16),
        _buildRatingSlider(
          'Care Quality',
          'careQuality',
          Icons.favorite_outline,
        ),
        const SizedBox(height: 16),
        _buildRatingSlider(
          'Communication',
          'communication',
          Icons.chat_bubble_outline,
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, String key, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _detailedRatings[key]!.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            valueIndicatorColor: AppColors.primary,
          ),
          child: Slider(
            value: _detailedRatings[key]!,
            min: 1,
            max: 5,
            divisions: 8,
            label: _detailedRatings[key]!.toStringAsFixed(1),
            onChanged: (value) => setState(() => _detailedRatings[key] = value),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Review',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please write a review';
            }
            if (value.trim().length < 10) {
              return 'Review must be at least 10 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Photos (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _selectedPhotos.length < 5 ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate, size: 20),
              label: Text('${_selectedPhotos.length}/5'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        if (_selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(_selectedPhotos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRating,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
