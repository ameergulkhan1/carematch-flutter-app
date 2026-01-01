import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/caregiver_user_model.dart';
import '../../../models/booking_model.dart';
import '../../../services/enhanced_booking_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/phone_number_input.dart';

/// Stage 1-2: Booking Request Creation Screen
/// Client fills booking form with service details, care plan, and special requirements
class BookingRequestScreen extends StatefulWidget {
  final CaregiverUser caregiver;

  const BookingRequestScreen({super.key, required this.caregiver});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedBookingService _bookingService = EnhancedBookingService();

  // Form Controllers
  final _specialRequirementsController = TextEditingController();
  final _requestMessageController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Phone country data
  String _phoneCountryCode = 'US';
  String _phoneDialCode = '+1';

  // Form State
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startTime;
  String? _endTime;
  ServiceType _selectedServiceType = ServiceType.eldercare;
  BookingType _bookingType = BookingType.oneTime;
  
  // Care Plan
  final List<String> _selectedTasks = [];
  bool _medicationRequired = false;
  bool _mobilityHelpRequired = false;
  bool _mealPrepRequired = false;
  bool _schoolPickupRequired = false;

  // Time Slots
  final List<String> _timeSlots = [
    '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
    '06:00 PM', '07:00 PM', '08:00 PM', '09:00 PM', '10:00 PM',
  ];

  // Available Tasks
  final List<String> _availableTasks = [
    'Bathing & Personal Hygiene',
    'Dressing & Grooming',
    'Medication Reminders',
    'Light Housekeeping',
    'Laundry',
    'Meal Preparation',
    'Companionship',
    'Transportation',
    'Doctor Appointments',
    'Exercise Support',
    'Reading & Activities',
  ];

  bool _isLoading = false;
  double? _hourlyRate;
  int _totalHours = 0;

  @override
  void initState() {
    super.initState();
    // Default hourly rate - can be enhanced later with actual rate field
    _hourlyRate = 25.0;
  }

  void _calculateHours() {
    if (_startDate != null && _endDate != null && _startTime != null && _endTime != null) {
      // Simple calculation - you can enhance this
      final days = _endDate!.difference(_startDate!).inDays + 1;
      final startHour = _parseTimeToHour(_startTime!);
      final endHour = _parseTimeToHour(_endTime!);
      final hoursPerDay = endHour - startHour;
      
      setState(() {
        _totalHours = days * hoursPerDay;
      });
    }
  }

  int _parseTimeToHour(String time) {
    final parts = time.split(' ');
    var hour = int.parse(parts[0].split(':')[0]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    if (parts[1] == 'AM' && hour == 12) hour = 0;
    return hour;
  }

  Future<void> _submitBookingRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showError('Please select start and end dates');
      return;
    }

    if (_startTime == null || _endTime == null) {
      _showError('Please select start and end times');
      return;
    }

    if (_selectedTasks.isEmpty) {
      _showError('Please select at least one task');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final clientUser = authProvider.currentUser;

      if (clientUser == null) {
        _showError('Please log in to book a caregiver');
        return;
      }

      final bookingId = await _bookingService.createBookingRequest(
        clientId: clientUser.uid,
        clientName: clientUser.displayName ?? clientUser.email ?? 'Client',
        caregiverId: widget.caregiver.uid,
        caregiverName: widget.caregiver.fullName,
        caregiverImageUrl: null, // CaregiverUser doesn't have profilePhotoUrl field
        startDate: _startDate!,
        endDate: _endDate!,
        startTime: _startTime,
        endTime: _endTime,
        bookingType: _bookingType,
        serviceType: _selectedServiceType,
        services: widget.caregiver.specializations, // Use specializations as services
        specialRequirements: _specialRequirementsController.text.trim(),
        tasks: _selectedTasks,
        medicationRequired: _medicationRequired,
        mobilityHelpRequired: _mobilityHelpRequired,
        mealPrepRequired: _mealPrepRequired,
        schoolPickupRequired: _schoolPickupRequired,
        carePlanDetails: _buildCarePlanSummary(),
        hourlyRate: _hourlyRate!,
        totalHours: _totalHours,
        clientAddress: {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zip': _zipController.text.trim(),
        },
        clientPhone: _phoneController.text.trim(),
        clientPhoneCountryCode: _phoneCountryCode,
        clientPhoneDialCode: _phoneDialCode,
        caregiverPhone: widget.caregiver.phoneNumber,
        caregiverPhoneCountryCode: widget.caregiver.phoneCountryCode,
        caregiverPhoneDialCode: widget.caregiver.phoneDialCode,
        requestMessage: _requestMessageController.text.trim(),
      );

      if (bookingId != null) {
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessDialog();
        }
      } else {
        _showError('Failed to create booking request. Please try again.');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildCarePlanSummary() {
    return '''
Tasks: ${_selectedTasks.join(', ')}
Medication Required: ${_medicationRequired ? 'Yes' : 'No'}
Mobility Help: ${_mobilityHelpRequired ? 'Yes' : 'No'}
Meal Prep: ${_mealPrepRequired ? 'Yes' : 'No'}
School Pickup: ${_schoolPickupRequired ? 'Yes' : 'No'}
    ''';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        title: const Text('Booking Request Sent!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your booking request has been sent to ${widget.caregiver.fullName}.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'You will be notified when the caregiver responds.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to profile
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _hourlyRate! * _totalHours;
    final platformFee = totalAmount * 0.15;
    final finalAmount = totalAmount + platformFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Caregiver'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Caregiver Info Card
                _buildCaregiverCard(),
                const SizedBox(height: 24),

                // Service Type Selection
                _buildSectionTitle('Service Type'),
                _buildServiceTypeSelector(),
                const SizedBox(height: 24),

                // Booking Type
                _buildSectionTitle('Booking Type'),
                _buildBookingTypeSelector(),
                const SizedBox(height: 24),

                // Date & Time Selection
                _buildSectionTitle('Schedule'),
                _buildDateTimeSelectors(),
                const SizedBox(height: 24),

                // Care Plan
                _buildSectionTitle('Care Plan & Tasks'),
                _buildTaskSelector(),
                const SizedBox(height: 16),
                _buildSpecialNeedsToggles(),
                const SizedBox(height: 24),

                // Location
                _buildSectionTitle('Service Location'),
                _buildLocationFields(),
                const SizedBox(height: 24),

                // Special Requirements
                _buildSectionTitle('Additional Requirements'),
                _buildSpecialRequirementsField(),
                const SizedBox(height: 16),
                _buildMessageField(),
                const SizedBox(height: 24),

                // Contact Info
                _buildSectionTitle('Contact Information'),
                _buildPhoneField(),
                const SizedBox(height: 24),

                // Cost Breakdown
                _buildCostBreakdown(totalAmount, platformFee, finalAmount),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaregiverCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                widget.caregiver.fullName[0].toUpperCase(),
                style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.caregiver.fullName, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text('5.0'), // Default rating - enhance later with actual rating field
                      const SizedBox(width: 16),
                      Text(
                        '\$${_hourlyRate!.toStringAsFixed(0)}/hr',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Verified', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildServiceTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceTypeChip('Eldercare', ServiceType.eldercare, Icons.elderly),
            _buildServiceTypeChip('Childcare', ServiceType.childcare, Icons.child_care),
            _buildServiceTypeChip('Special Needs', ServiceType.specialNeeds, Icons.accessible),
            _buildServiceTypeChip('Companionship', ServiceType.companionship, Icons.people),
            _buildServiceTypeChip('Medical Care', ServiceType.medicalCare, Icons.medical_services),
            _buildServiceTypeChip('Dementia Care', ServiceType.dementiaCare, Icons.psychology),
            _buildServiceTypeChip('Meal Preparation', ServiceType.mealPreparation, Icons.restaurant),
            _buildServiceTypeChip('Transportation', ServiceType.transportation, Icons.directions_car),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeChip(String label, ServiceType type, IconData icon) {
    final isSelected = _selectedServiceType == type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedServiceType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<BookingType>(
                title: const Text('One-time'),
                value: BookingType.oneTime,
                groupValue: _bookingType,
                onChanged: (value) => setState(() => _bookingType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<BookingType>(
                title: const Text('Recurring'),
                value: BookingType.recurring,
                groupValue: _bookingType,
                onChanged: (value) => setState(() => _bookingType = value!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelectors() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Start Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text('Start Date'),
              subtitle: Text(_startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select date'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                  _calculateHours();
                }
              },
            ),
            const Divider(),
            // End Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text('End Date'),
              subtitle: Text(_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select date'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _endDate = date);
                  _calculateHours();
                }
              },
            ),
            const Divider(),
            // Start Time
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: const Text('Start Time'),
              subtitle: Text(_startTime ?? 'Select time'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showTimeSelector(true),
            ),
            const Divider(),
            // End Time
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: const Text('End Time'),
              subtitle: Text(_endTime ?? 'Select time'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showTimeSelector(false),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeSelector(bool isStartTime) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              isStartTime ? 'Select Start Time' : 'Select End Time',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _timeSlots.length,
                itemBuilder: (context, index) {
                  final time = _timeSlots[index];
                  return ListTile(
                    title: Text(time),
                    trailing: (isStartTime && _startTime == time) || (!isStartTime && _endTime == time)
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        if (isStartTime) {
                          _startTime = time;
                        } else {
                          _endTime = time;
                        }
                      });
                      _calculateHours();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select required tasks:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTasks.map((task) {
                final isSelected = _selectedTasks.contains(task);
                return FilterChip(
                  label: Text(task),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTasks.add(task);
                      } else {
                        _selectedTasks.remove(task);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialNeedsToggles() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Medication Required'),
              subtitle: const Text('Assistance with medication management'),
              value: _medicationRequired,
              onChanged: (value) => setState(() => _medicationRequired = value),
            ),
            SwitchListTile(
              title: const Text('Mobility Help Needed'),
              subtitle: const Text('Support with walking, wheelchair, etc.'),
              value: _mobilityHelpRequired,
              onChanged: (value) => setState(() => _mobilityHelpRequired = value),
            ),
            SwitchListTile(
              title: const Text('Meal Preparation'),
              subtitle: const Text('Cooking and meal planning'),
              value: _mealPrepRequired,
              onChanged: (value) => setState(() => _mealPrepRequired = value),
            ),
            SwitchListTile(
              title: const Text('School Pickup'),
              subtitle: const Text('Pick up from school (childcare only)'),
              value: _schoolPickupRequired,
              onChanged: (value) => setState(() => _schoolPickupRequired = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: '123 Main Street',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialRequirementsField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _specialRequirementsController,
          decoration: const InputDecoration(
            labelText: 'Special Requirements',
            hintText: 'Any specific needs or instructions...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildMessageField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _requestMessageController,
          decoration: const InputDecoration(
            labelText: 'Message to Caregiver (Optional)',
            hintText: 'Introduce yourself and share any additional details...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PhoneNumberInput(
          controller: _phoneController,
          labelText: 'Contact Phone',
          hintText: 'Enter your phone number',
          onCountryChanged: (country) {
            setState(() {
              _phoneCountryCode = country.code;
              _phoneDialCode = country.dialCode;
            });
          },
          validator: (value) => value!.isEmpty ? 'Phone number is required' : null,
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(double totalAmount, double platformFee, double finalAmount) {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cost Breakdown', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildCostRow('Hourly Rate', '\$${_hourlyRate!.toStringAsFixed(2)}'),
            _buildCostRow('Total Hours', '$_totalHours hours'),
            _buildCostRow('Subtotal', '\$${totalAmount.toStringAsFixed(2)}'),
            _buildCostRow('Platform Fee (15%)', '\$${platformFee.toStringAsFixed(2)}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '\$${finalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Payment will be processed after caregiver accepts your request',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitBookingRequest,
        icon: const Icon(Icons.send),
        label: const Text('Send Booking Request', style: TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _specialRequirementsController.dispose();
    _requestMessageController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
