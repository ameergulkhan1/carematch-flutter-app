import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/care_plan_model.dart';
import '../../../../services/care_plan_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'create_care_plan_screen.dart';

class CarePlanListScreen extends StatefulWidget {
  const CarePlanListScreen({super.key});

  @override
  State<CarePlanListScreen> createState() => _CarePlanListScreenState();
}

class _CarePlanListScreenState extends State<CarePlanListScreen> {
  final CarePlanService _carePlanService = CarePlanService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Care Plans'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view care plans'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Care Plans'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CarePlan>>(
        stream: _carePlanService.getClientCarePlans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final carePlans = snapshot.data ?? [];

          if (carePlans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No care plans yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Create your first care plan to get started'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateCarePlan(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Care Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: carePlans.length,
            itemBuilder: (context, index) {
              final carePlan = carePlans[index];
              return _buildCarePlanCard(context, carePlan);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateCarePlan(context),
        backgroundColor: AppColors.primary,
        label: const Text('New Care Plan'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCarePlanCard(BuildContext context, CarePlan carePlan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCarePlanDetails(context, carePlan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCareTypeIcon(carePlan.careType),
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carePlan.careTypeLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          carePlan.frequencyLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: carePlan.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      carePlan.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: carePlan.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                carePlan.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                    Icons.access_time,
                    '${carePlan.hoursPerSession} hrs/session',
                  ),
                  _buildInfoChip(
                    Icons.task_alt,
                    '${carePlan.tasks.length} tasks',
                  ),
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${carePlan.startDate.day}/${carePlan.startDate.month}/${carePlan.startDate.year}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.grey.shade600),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  IconData _getCareTypeIcon(CareType type) {
    switch (type) {
      case CareType.childcare:
        return Icons.child_care;
      case CareType.elderlyCare:
        return Icons.elderly;
      case CareType.specialNeeds:
        return Icons.accessible;
      case CareType.companionship:
        return Icons.people;
      case CareType.medicalCare:
        return Icons.medical_services;
      case CareType.dementiaCare:
        return Icons.psychology;
    }
  }

  void _showCarePlanDetails(BuildContext context, CarePlan carePlan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCareTypeIcon(carePlan.careType),
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carePlan.careTypeLabel,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            carePlan.frequencyLabel,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailSection('Description', carePlan.description),
                const SizedBox(height: 16),
                _buildDetailSection(
                  'Session Duration',
                  '${carePlan.hoursPerSession} hours per session',
                ),
                const SizedBox(height: 16),
                _buildDetailSection('Tasks', carePlan.tasks.join('\n• ')),
                const SizedBox(height: 16),
                _buildDetailSection(
                  'Schedule',
                  '${carePlan.startDate.day}/${carePlan.startDate.month}/${carePlan.startDate.year} ${carePlan.endDate != null ? '- ${carePlan.endDate!.day}/${carePlan.endDate!.month}/${carePlan.endDate!.year}' : '(ongoing)'}',
                ),
                if (carePlan.specificDays.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection('Days', carePlan.specificDays.join(', ')),
                ],
                if (carePlan.preferredStartTime != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailSection(
                    'Preferred Time',
                    '${carePlan.preferredStartTime} - ${carePlan.preferredEndTime}',
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deactivateCarePlan(carePlan);
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Deactivate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Navigate to edit screen
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _navigateToCreateCarePlan(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCarePlanScreen(),
      ),
    );

    if (result == true && mounted) {
      // Refresh will happen automatically via stream
    }
  }

  Future<void> _deactivateCarePlan(CarePlan carePlan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Care Plan'),
        content: const Text(
          'Are you sure you want to deactivate this care plan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _carePlanService.deactivateCarePlan(carePlan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Care plan deactivated'
                  : 'Failed to deactivate care plan',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
