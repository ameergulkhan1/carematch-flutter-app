import 'package:flutter/material.dart';
import '../client_colors.dart';
import '../../../../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 260 : 70,
      decoration: const BoxDecoration(
        color: ClientColors.sidebarBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile section
          Container(
            padding: EdgeInsets.all(isExpanded ? 20 : 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: isExpanded ? 35 : 20,
                  backgroundColor: ClientColors.primary,
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isExpanded ? 24 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ClientColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CLIENT',
                      style: TextStyle(
                        color: ClientColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.search,
                  label: 'Find Caregivers',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.calendar_month,
                  label: 'My Bookings',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.message,
                  label: 'Messages',
                  index: 4,
                ),
                _buildNavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  index: 5,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 6,
                ),
              ],
            ),
          ),

          // Toggle button
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
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? ClientColors.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? ClientColors.primary : Colors.white70,
                  size: 22,
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
}
