import 'package:flutter/material.dart';
import '../caregiver_colors.dart';
import '../../../../../shared/utils/responsive_utils.dart';

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
    final isMobile = ResponsiveUtils.isMobile(context);
    final sidebarWidth =
        ResponsiveUtils.getSidebarWidth(context, isExpanded: isExpanded);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isMobile ? double.infinity : sidebarWidth,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CaregiverColors.sidebarBg,
            Color(0xFF0F1419),
          ],
        ),
        border: const Border(
          right: BorderSide(color: Colors.black26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMenuItems(context),
                  SizedBox(height: isMobile ? 20 : 40),
                ],
              ),
            ),
          ),
          if (!isMobile) _buildCollapseButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CaregiverColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: (isExpanded || isMobile) ? 24 : 20,
              backgroundColor: CaregiverColors.primary,
              child: Text(
                caregiverName.isNotEmpty ? caregiverName[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: (isExpanded || isMobile) ? 20 : 16,
                ),
              ),
            ),
          ),
          if (isExpanded || isMobile) ...[
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caregiverName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 14 : 15,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CaregiverColors.primary.withOpacity(0.3),
                          CaregiverColors.primaryLight.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CaregiverColors.primary.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'VERIFIED',
                      style: TextStyle(
                        color: CaregiverColors.primaryLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
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

  Widget _buildMenuItems(BuildContext context) {
    final menuItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.calendar_today, 'label': 'Bookings'},
      {'icon': Icons.message_outlined, 'label': 'Messages'},
      {'icon': Icons.account_balance_wallet, 'label': 'Earnings'},
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
          context,
          item['icon'] as IconData,
          item['label'] as String,
          index,
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    CaregiverColors.primary.withOpacity(0.9),
                    CaregiverColors.primaryDark.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: CaregiverColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: () => onMenuItemTapped(index),
          borderRadius: BorderRadius.circular(10),
          hoverColor: CaregiverColors.sidebarHover.withOpacity(0.5),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 16,
              vertical: isMobile ? 12 : 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                  size: isMobile ? 22 : 24,
                ),
                if (isExpanded || isMobile) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: isMobile ? 14 : 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        hoverColor: CaregiverColors.sidebarHover.withOpacity(0.5),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CaregiverColors.sidebarHover.withOpacity(0.8),
                CaregiverColors.sidebarHover.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            isExpanded ? Icons.chevron_left : Icons.chevron_right,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ),
      ),
    );
  }
}
