import 'package:flutter/material.dart';
import '../caregiver_colors.dart';

class CaregiverSidebar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final Function(int) onMenuItemTapped;
  final VoidCallback onToggle;
  final String caregiverName;

  const CaregiverSidebar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onMenuItemTapped,
    required this.onToggle,
    required this.caregiverName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 260 : 70,
      decoration: const BoxDecoration(
        color: CaregiverColors.sidebarBg,
        border: Border(
          right: BorderSide(color: Colors.black12),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMenuItems(),
          const Spacer(),
          _buildCollapseButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: CaregiverColors.primary,
            child: Text(
              caregiverName.isNotEmpty ? caregiverName[0].toUpperCase() : 'C',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caregiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: CaregiverColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.calendar_today, 'label': 'Bookings'},
      {'icon': Icons.access_time, 'label': 'Availability'},
      {'icon': Icons.person, 'label': 'Profile'},
      {'icon': Icons.star, 'label': 'Reviews'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildMenuItem(
          item['icon'] as IconData,
          item['label'] as String,
          index,
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onMenuItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CaregiverColors.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? CaregiverColors.primary : Colors.white70,
              size: 22,
            ),
            if (isExpanded) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return InkWell(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CaregiverColors.sidebarHover,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white70,
        ),
      ),
    );
  }
}
