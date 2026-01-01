import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/responsive_utils.dart';

class CaregiverFilterPanel extends StatelessWidget {
  final List<String> selectedServices;
  final int? minExperience;
  final String? selectedCity;
  final List<String> availableServices;
  final List<String> availableCities;
  final VoidCallback onClearFilters;
  final Function(List<String>) onServicesChanged;
  final Function(int?) onExperienceChanged;
  final Function(String?) onCityChanged;

  const CaregiverFilterPanel({
    super.key,
    required this.selectedServices,
    required this.minExperience,
    required this.selectedCity,
    required this.availableServices,
    required this.availableCities,
    required this.onClearFilters,
    required this.onServicesChanged,
    required this.onExperienceChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = isMobile ? screenHeight * 0.6 : screenHeight * 0.5;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context, isMobile),
          
          Divider(height: 1, color: Colors.grey.shade200),
          
          // Filters Content - Always scrollable
          Flexible(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location and Experience filters
                  _buildLocationExperienceFilters(context, isMobile),
                  
                  const SizedBox(height: 20),
                  
                  // Services filter
                  _buildServicesFilter(context, isMobile),
                  
                  // Add bottom padding for better UX
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: ResponsiveUtils.getFontSize(context,
                    mobile: 20, tablet: 22, desktop: 24),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Filter Caregivers',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context,
                      mobile: 17, tablet: 18, desktop: 19),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onClearFilters,
            icon: Icon(
              Icons.clear_all,
              size: ResponsiveUtils.getFontSize(context,
                  mobile: 16, tablet: 17, desktop: 18),
            ),
            label: Text(
              'Clear All',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 13, tablet: 14, desktop: 15),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 14,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationExperienceFilters(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCityFilter(context, isMobile),
          const SizedBox(height: 16),
          _buildExperienceFilter(context, isMobile),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCityFilter(context, isMobile)),
          const SizedBox(width: 16),
          Expanded(child: _buildExperienceFilter(context, isMobile)),
        ],
      );
    }
  }

  Widget _buildCityFilter(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_city,
              size: ResponsiveUtils.getFontSize(context,
                  mobile: 16, tablet: 17, desktop: 18),
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Location',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 14, tablet: 15, desktop: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedCity != null
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: selectedCity != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedCity,
            isExpanded: true,
            menuMaxHeight: 300,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text(
              'All Cities',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 13, tablet: 14, desktop: 15),
                color: AppColors.textSecondary,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'All Cities',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context,
                        mobile: 13, tablet: 14, desktop: 15),
                  ),
                ),
              ),
              ...availableCities.map((city) => DropdownMenuItem(
                    value: city,
                    child: Text(
                      city,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context,
                            mobile: 13, tablet: 14, desktop: 15),
                      ),
                    ),
                  )),
            ],
            onChanged: onCityChanged,
            icon: Icon(
              Icons.expand_more,
              color: AppColors.textSecondary,
              size: isMobile ? 20 : 22,
            ),
            dropdownColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceFilter(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.work_history,
              size: ResponsiveUtils.getFontSize(context,
                  mobile: 16, tablet: 17, desktop: 18),
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Experience',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 14, tablet: 15, desktop: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: minExperience != null
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: minExperience != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonFormField<int>(
            value: minExperience,
            isExpanded: true,
            menuMaxHeight: 300,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text(
              'Any Experience',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 13, tablet: 14, desktop: 15),
                color: AppColors.textSecondary,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'Any Experience',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context,
                        mobile: 13, tablet: 14, desktop: 15),
                  ),
                ),
              ),
              ...[1, 2, 3, 5, 10].map((years) => DropdownMenuItem(
                    value: years,
                    child: Text(
                      '$years+ year${years > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context,
                            mobile: 13, tablet: 14, desktop: 15),
                      ),
                    ),
                  )),
            ],
            onChanged: onExperienceChanged,
            icon: Icon(
              Icons.expand_more,
              color: AppColors.textSecondary,
              size: isMobile ? 20 : 22,
            ),
            dropdownColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesFilter(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_services,
              size: ResponsiveUtils.getFontSize(context,
                  mobile: 16, tablet: 17, desktop: 18),
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Services',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 14, tablet: 15, desktop: 16),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (selectedServices.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${selectedServices.length} selected',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context,
                        mobile: 11, tablet: 12, desktop: 13),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: isMobile ? 8 : 10,
          runSpacing: isMobile ? 8 : 10,
          children: availableServices.map((service) {
            final isSelected = selectedServices.contains(service);
            return FilterChip(
              label: Text(
                service,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context,
                      mobile: 12, tablet: 13, desktop: 14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newServices = List<String>.from(selectedServices);
                if (selected) {
                  newServices.add(service);
                } else {
                  newServices.remove(service);
                }
                onServicesChanged(newServices);
              },
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 14,
                vertical: isMobile ? 8 : 10,
              ),
              labelPadding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
            );
          }).toList(),
        ),
      ],
    );
  }
}
