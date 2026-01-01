import 'package:flutter/material.dart';
import '../client_colors.dart';
import '../../../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../../shared/utils/responsive_utils.dart';

class ClientSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ClientSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.clientUser?.fullName ?? 'Client';
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

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
            ClientColors.sidebarBg,
            Color(0xFF0F1419),
          ],
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
          // Profile section
          Container(
            padding: EdgeInsets.all(isExpanded || isMobile ? 24 : 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ClientColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: isExpanded || isMobile ? 36 : 22,
                    backgroundColor: ClientColors.primary,
                    child: Text(
                      userName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isExpanded || isMobile ? 26 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isExpanded || isMobile) ...[
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ClientColors.primary.withOpacity(0.2),
                          ClientColors.primaryLight.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ClientColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'CLIENT',
                      style: TextStyle(
                        color: ClientColors.primaryLight,
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.search,
                  label: 'Find Caregivers',
                  index: 1,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.calendar_month,
                  label: 'My Bookings',
                  index: 2,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.favorite,
                  label: 'Favorites',
                  index: 3,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.message,
                  label: 'Messages',
                  index: 4,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.star,
                  label: 'My Reviews',
                  index: 5,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.report_problem,
                  label: 'Incidents',
                  index: 6,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.receipt_long,
                  label: 'Billing',
                  index: 7,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person,
                  label: 'Profile',
                  index: 8,
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 9,
                ),
              ],
            ),
          ),

          // Toggle button (hide on mobile)
          if (!isMobile)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Icon(
                      isExpanded ? Icons.chevron_left : Icons.chevron_right,
                      color: Colors.white,
                    ),
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
    final isSelected = selectedIndex == index;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isMobile ? 2 : 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    ClientColors.primary.withOpacity(0.9),
                    ClientColors.primaryDark.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ClientColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemSelected(index),
            borderRadius: BorderRadius.circular(12),
            hoverColor: ClientColors.sidebarHover.withOpacity(0.5),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: isMobile ? 12 : 14,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
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
                          fontSize: isMobile ? 14 : 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
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
      ),
    );
  }
}
