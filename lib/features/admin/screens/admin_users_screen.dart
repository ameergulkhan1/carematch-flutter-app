import 'package:flutter/material.dart';
import '../widgets/user_data_table.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _adminService = AdminService();
  String _selectedRole = 'all';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          const SizedBox(height: 24),
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: _buildUsersTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            
            if (isSmallScreen) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.filter_list),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Filter by Role:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Users')),
                        DropdownMenuItem(value: 'client', child: Text('Clients')),
                        DropdownMenuItem(value: 'caregiver', child: Text('Caregivers')),
                        DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ),
                ],
              );
            }
            
            return Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 12),
                const Text(
                  'Filter by Role:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Users')),
                    DropdownMenuItem(value: 'client', child: Text('Clients')),
                    DropdownMenuItem(value: 'caregiver', child: Text('Caregivers')),
                    DropdownMenuItem(value: 'admin', child: Text('Admins')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getAllUsers(
        roleFilter: _selectedRole == 'all' ? null : _selectedRole,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return UserDataTable(users: users);
      },
    );
  }
}
