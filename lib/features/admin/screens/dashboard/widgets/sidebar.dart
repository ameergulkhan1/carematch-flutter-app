import 'package:flutter/material.dart';
import '../admin_colors.dart';
import '../../../../../shared/utils/responsive_utils.dart';

class AdminSidebarNew extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AdminSidebarNew({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final sidebarWidth = ResponsiveUtils.getSidebarWidth(context, isExpanded: isExpanded);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isMobile ? double.infinity : sidebarWidth,
      decoration: const BoxDecoration(
        color: AdminColors.sidebarBg,
        border: Border(
          right: BorderSide(color: Color(0xFF374151), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header with Logo
          Container(
            height: isMobile ? 60 : 70,
            padding: EdgeInsets.symmetric(horizontal: (isExpanded || isMobile) ? 16 : 0),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF374151), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: (isExpanded || isMobile) ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (!isExpanded && !isMobile)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (isExpanded || isMobile) ...[
                  Container(
                    width: isMobile ? 32 : 38,
                    height: isMobile ? 32 : 38,
                    decoration: BoxDecoration(
                      color: AdminColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: isMobile ? 18 : 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CareMatch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isMobile ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.people_outline,
                  label: 'Users',
                  index: 1,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.medical_services_outlined,
                  label: 'Caregivers',
                  index: 2,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.verified_user_outlined,
                  label: 'Verifications',
                  index: 3,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  index: 4,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  label: 'Bookings',
                  index: 5,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  index: 6,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  index: 7,
                ),
              ],
            ),
          ),

          // Collapse Button - Hide on mobile
          if (!isMobile)
            Container(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminColors.sidebarHover,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isExpanded ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'Collapse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = selectedIndex == index;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: (isExpanded || isMobile) ? 12 : 8,
        vertical: isMobile ? 3 : 4,
      ),
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: isMobile ? 40 : 44,
          decoration: BoxDecoration(
            color: isActive ? AdminColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: (isExpanded || isMobile) ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              SizedBox(
                width: (isExpanded || isMobile) ? 44 : null,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              if (isExpanded || isMobile)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
