import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SavedCaregiversScreen extends StatelessWidget {
  const SavedCaregiversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Caregivers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Saved Caregivers - Coming Soon'),
      ),
    );
  }
}
