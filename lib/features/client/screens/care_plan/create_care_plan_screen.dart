import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/care_plan_model.dart';
import '../../../../services/care_plan_service.dart';
import '../../../../core/constants/app_colors.dart';

class CreateCarePlanScreen extends StatefulWidget {
  const CreateCarePlanScreen({super.key});

  @override
  State<CreateCarePlanScreen> createState() => _CreateCarePlanScreenState();
}

class _CreateCarePlanScreenState extends State<CreateCarePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final CarePlanService _carePlanService = CarePlanService();
  
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Form data
  CareType _selectedCareType = CareType.companionship;
  final TextEditingController _descriptionController = TextEditingController();
  int _hoursPerSession = 2;
  ScheduleFrequency _frequency = ScheduleFrequency.weekly;
  final List<String> _selectedTasks = [];
  final Map<String, dynamic> _preferences = {};
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final List<String> _specificDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  // Predefined tasks by care type
  final Map<CareType, List<String>> _tasksByType = {
    CareType.childcare: [
      'Meal preparation',
      'Diaper changing',
      'Playtime activities',
      'Homework help',
      'Bathing',
      'Bedtime routine',
    ],
    CareType.elderlyCare: [
      'Medication reminders',
      'Meal preparation',
      'Personal hygiene assistance',
      'Light housekeeping',
      'Companionship',
      'Mobility assistance',
    ],
    CareType.specialNeeds: [
      'Medication administration',
      'Therapy exercises',
      'Mobility support',
      'Communication assistance',
      'Personal care',
      'Activity engagement',
    ],
    CareType.companionship: [
      'Conversation',
      'Social activities',
      'Light housekeeping',
      'Meal preparation',
      'Errands',
      'Entertainment',
    ],
    CareType.medicalCare: [
      'Medication management',
      'Vital signs monitoring',
      'Wound care',
      'IV management',
      'Physical therapy',
      'Medical appointments',
    ],
    CareType.dementiaCare: [
      'Memory activities',
      'Safety monitoring',
      'Personal care',
      'Meal assistance',
      'Behavioral support',
      'Routine maintenance',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Care Plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _currentStep < 3 ? _nextStep : _submitCarePlan,
          onStepCancel: _currentStep > 0 ? _previousStep : null,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  if (_currentStep < 3)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Continue'),
                    ),
                  if (_currentStep == 3)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Care Plan'),
                    ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Care Type & Description'),
              isActive: _currentStep >= 0,
              content: _buildStep1(),
            ),
            Step(
              title: const Text('Tasks & Preferences'),
              isActive: _currentStep >= 1,
              content: _buildStep2(),
            ),
            Step(
              title: const Text('Schedule'),
              isActive: _currentStep >= 2,
              content: _buildStep3(),
            ),
            Step(
              title: const Text('Review'),
              isActive: _currentStep >= 3,
              content: _buildStep4(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Care Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: CareType.values.map((type) {
            final isSelected = _selectedCareType == type;
            return ChoiceChip(
              label: Text(_getCareTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCareType = type;
                    _selectedTasks.clear(); // Clear tasks when changing care type
                  });
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe your care needs and expectations...',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Hours per Session',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _hoursPerSession.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '$_hoursPerSession hours',
                onChanged: (value) {
                  setState(() {
                    _hoursPerSession = value.toInt();
                  });
                },
              ),
            ),
            Text(
              '$_hoursPerSession hours',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final availableTasks = _tasksByType[_selectedCareType] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Tasks',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...availableTasks.map((task) {
          final isSelected = _selectedTasks.contains(task);
          return CheckboxListTile(
            title: Text(task),
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedTasks.add(task);
                } else {
                  _selectedTasks.remove(task);
                }
              });
            },
            activeColor: AppColors.primary,
          );
        }),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Add Custom Task',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Enter custom task...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty && !_selectedTasks.contains(value.trim())) {
                    setState(() {
                      _selectedTasks.add(value.trim());
                    });
                  }
                },
              ),
            ),
          ],
        ),
        if (_selectedTasks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Please select at least one task',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ScheduleFrequency.values.map((freq) {
            final isSelected = _frequency == freq;
            return ChoiceChip(
              label: Text(_getFrequencyLabel(freq)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _frequency = freq;
                  });
                }
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Start Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: Text(
            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
            style: const TextStyle(fontSize: 16),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _startDate = date;
              });
            }
          },
          tileColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 16),
        const Text(
          'End Date (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: Text(
            _endDate != null
                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                : 'No end date',
            style: const TextStyle(fontSize: 16),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
              firstDate: _startDate,
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (date != null) {
              setState(() {
                _endDate = date;
              });
            }
          },
          tileColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        if (_frequency == ScheduleFrequency.weekly || _frequency == ScheduleFrequency.biWeekly) ...[
          const SizedBox(height: 24),
          const Text(
            'Select Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) {
              final isSelected = _specificDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _specificDays.add(day);
                    } else {
                      _specificDays.remove(day);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Preferred Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Start'),
                subtitle: Text(_startTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = time;
                    });
                  }
                },
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ListTile(
                title: const Text('End'),
                subtitle: Text(_endTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (time != null) {
                    setState(() {
                      _endTime = time;
                    });
                  }
                },
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Care Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildReviewItem('Care Type', _getCareTypeLabel(_selectedCareType)),
        _buildReviewItem('Description', _descriptionController.text),
        _buildReviewItem('Hours per Session', '$_hoursPerSession hours'),
        _buildReviewItem('Frequency', _getFrequencyLabel(_frequency)),
        _buildReviewItem('Tasks', _selectedTasks.join(', ')),
        _buildReviewItem(
          'Start Date',
          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
        ),
        if (_endDate != null)
          _buildReviewItem(
            'End Date',
            '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
          ),
        if (_specificDays.isNotEmpty)
          _buildReviewItem('Days', _specificDays.join(', ')),
        _buildReviewItem(
          'Preferred Time',
          '${_startTime.format(context)} - ${_endTime.format(context)}',
        ),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      return;
    }
    if (_currentStep == 1 && _selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one task')),
      );
      return;
    }
    if (_currentStep == 2 && (_frequency == ScheduleFrequency.weekly || _frequency == ScheduleFrequency.biWeekly) && _specificDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }
    setState(() {
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
    });
  }

  Future<void> _submitCarePlan() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final carePlan = CarePlan(
        id: '',
        clientId: user.uid,
        clientName: user.displayName ?? user.email ?? 'User',
        careType: _selectedCareType,
        description: _descriptionController.text,
        hoursPerSession: _hoursPerSession,
        frequency: _frequency,
        tasks: _selectedTasks,
        preferences: _preferences,
        startDate: _startDate,
        endDate: _endDate,
        specificDays: _specificDays,
        preferredStartTime: _startTime.format(context),
        preferredEndTime: _endTime.format(context),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final carePlanId = await _carePlanService.createCarePlan(carePlan);

      if (carePlanId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Care plan created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to create care plan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getCareTypeLabel(CareType type) {
    switch (type) {
      case CareType.childcare:
        return 'Childcare';
      case CareType.elderlyCare:
        return 'Elderly Care';
      case CareType.specialNeeds:
        return 'Special Needs';
      case CareType.companionship:
        return 'Companionship';
      case CareType.medicalCare:
        return 'Medical Care';
      case CareType.dementiaCare:
        return 'Dementia Care';
    }
  }

  String _getFrequencyLabel(ScheduleFrequency freq) {
    switch (freq) {
      case ScheduleFrequency.oneTime:
        return 'One Time';
      case ScheduleFrequency.daily:
        return 'Daily';
      case ScheduleFrequency.weekly:
        return 'Weekly';
      case ScheduleFrequency.biWeekly:
        return 'Bi-Weekly';
      case ScheduleFrequency.monthly:
        return 'Monthly';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
