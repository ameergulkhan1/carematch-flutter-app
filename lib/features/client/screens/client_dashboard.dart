import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'CareMatch',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text('My Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.landing);
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.clientUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user.fullName}!',
                            style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.isEmailVerified 
                                ? 'Your account is verified and ready to use'
                                : 'Please verify your email to access all features',
                            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions
                    Text('Quick Actions', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          icon: Icons.search,
                          title: 'Find Caregivers',
                          description: 'Search for trusted caregivers',
                          onTap: () {},
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.calendar_month,
                          title: 'My Bookings',
                          description: 'View and manage bookings',
                          onTap: () {},
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.favorite_outline,
                          title: 'Favorites',
                          description: 'Saved caregivers',
                          onTap: () {},
                        ),
                        _buildActionCard(
                          context,
                          icon: Icons.message_outlined,
                          title: 'Messages',
                          description: 'Chat with caregivers',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Profile Summary
                    Text('Profile Information', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Email', user.email),
                          const Divider(height: 24),
                          _buildInfoRow('Phone', user.phoneNumber),
                          if (user.address != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow('Address', user.address!),
                          ],
                          if (user.city != null && user.state != null) ...[
                            const Divider(height: 24),
                            _buildInfoRow('Location', '${user.city}, ${user.state} ${user.zipCode ?? ''}'),
                          ],
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Email Status',
                            user.isEmailVerified ? 'Verified ✓' : 'Not Verified',
                            valueColor: user.isEmailVerified ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
