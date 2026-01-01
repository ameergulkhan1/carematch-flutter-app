import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/review_model.dart';
import '../../../../models/booking_model.dart';
import '../../../../services/review_service.dart';

class SubmitReviewScreen extends StatefulWidget {
  final BookingModel booking;

  const SubmitReviewScreen({super.key, required this.booking});

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  double _overallRating = 5.0;
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
      if (images.isNotEmpty && images.length <= 5) {
        setState(() {
          _selectedPhotos = images.map((xfile) => File(xfile.path)).toList();
        });
      } else if (images.length > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 photos allowed')),
          );
        }
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

  Future<void> _submitReview() async {
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

      // Create review
      final review = Review(
        id: '',
        bookingId: widget.booking.id,
        reviewerId: currentUser.uid,
        reviewerName: widget.booking.clientName,
        revieweeId: widget.booking.caregiverId,
        revieweeName: widget.booking.caregiverName,
        reviewerType: 'client',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Booking info
            _buildBookingInfo(),
            const SizedBox(height: 24),

            // Overall rating
            _buildOverallRating(),
            const SizedBox(height: 24),

            // Detailed ratings
            _buildDetailedRatings(),
            const SizedBox(height: 24),

            // Comment
            _buildCommentField(),
            const SizedBox(height: 24),

            // Photo upload
            _buildPhotoSection(),
            const SizedBox(height: 32),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: widget.booking.caregiverImageUrl != null
                      ? NetworkImage(widget.booking.caregiverImageUrl!)
                      : null,
                  child: widget.booking.caregiverImageUrl == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.caregiverName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.booking.serviceType.name,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Rating',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _overallRating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Column(
              children: List.generate(5, (index) {
                return Icon(
                  index < _overallRating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                  size: 32,
                );
              }),
            ),
          ],
        ),
        Slider(
          value: _overallRating,
          min: 1,
          max: 5,
          divisions: 8,
          label: _overallRating.toStringAsFixed(1),
          onChanged: (value) => setState(() => _overallRating = value),
        ),
      ],
    );
  }

  Widget _buildDetailedRatings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Ratings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildRatingSlider(
          'Professionalism',
          'professionalism',
          Icons.work_outline,
        ),
        _buildRatingSlider(
          'Punctuality',
          'punctuality',
          Icons.access_time,
        ),
        _buildRatingSlider(
          'Care Quality',
          'careQuality',
          Icons.favorite_outline,
        ),
        _buildRatingSlider(
          'Communication',
          'communication',
          Icons.chat_bubble_outline,
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, String key, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label),
              const Spacer(),
              Text(
                _detailedRatings[key]!.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _detailedRatings[key]!,
            min: 1,
            max: 5,
            divisions: 8,
            onChanged: (value) => setState(() => _detailedRatings[key] = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Review',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _commentController,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Share your experience with this caregiver...',
            border: OutlineInputBorder(),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _selectedPhotos.length < 5 ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedPhotos.isNotEmpty)
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
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedPhotos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
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
        if (_selectedPhotos.isEmpty)
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'No photos selected',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitReview,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
              'Submit Review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
