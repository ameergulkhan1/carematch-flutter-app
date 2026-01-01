import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import '../admin_routes.dart';

class AdminCaregiversScreen extends StatefulWidget {
  const AdminCaregiversScreen({super.key});

  @override
  State<AdminCaregiversScreen> createState() => _AdminCaregiversScreenState();
}

class _AdminCaregiversScreenState extends State<AdminCaregiversScreen> {
  final _adminService = AdminService();
  String _selectedFilter = 'all';

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
            child: _buildCaregiversList(),
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
                          'Filter by Status:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Caregivers')),
                        DropdownMenuItem(value: 'approved', child: Text('Verified')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending Verification')),
                        DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
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
                  'Filter by Status:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Caregivers')),
                    DropdownMenuItem(value: 'approved', child: Text('Verified')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending Verification')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
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

  Widget _buildCaregiversList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _adminService.getAllUsers(roleFilter: 'caregiver'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var caregivers = snapshot.data ?? [];

        // Apply verification status filter
        if (_selectedFilter != 'all') {
          caregivers = caregivers.where((caregiver) {
            final status = caregiver['verificationStatus'] ?? 'pending';
            return status == _selectedFilter;
          }).toList();
        }

        if (caregivers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No caregivers found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Experience', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Joined', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: caregivers.map((caregiver) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(
                                (caregiver['fullName'] ?? 'C')[0].toUpperCase(),
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(caregiver['fullName'] ?? 'N/A'),
                          ],
                        ),
                      ),
                      DataCell(Text(caregiver['email'] ?? 'N/A')),
                      DataCell(Text(caregiver['phone'] ?? 'N/A')),
                      DataCell(Text('${caregiver['yearsOfExperience'] ?? 0} years')),
                      DataCell(_buildStatusBadge(caregiver['verificationStatus'] ?? 'pending')),
                      DataCell(Text(_formatDate(caregiver['createdAt']))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 20),
                              tooltip: 'View Details',
                              onPressed: () => _viewCaregiverDetails(caregiver),
                            ),
                            IconButton(
                              icon: const Icon(Icons.verified_user, size: 20),
                              tooltip: 'View Verification',
                              onPressed: () {
                                Navigator.of(context).pushNamed(AdminRoutes.adminVerifications);
                              },
                            ),
                            if ((caregiver['verificationStatus'] ?? 'pending') != 'approved')
                              IconButton(
                                icon: Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
                                tooltip: 'Quick Approve',
                                onPressed: () => _quickApprove(caregiver),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Verified';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }

  void _viewCaregiverDetails(Map<String, dynamic> caregiver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${caregiver['fullName']} - Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', caregiver['email'] ?? 'N/A'),
              _buildDetailRow('Phone', caregiver['phone'] ?? 'N/A'),
              _buildDetailRow('Experience', '${caregiver['yearsOfExperience'] ?? 0} years'),
              _buildDetailRow('Specialization', caregiver['specialization'] ?? 'N/A'),
              _buildDetailRow('Hourly Rate', '\$${caregiver['hourlyRate'] ?? 0}'),
              _buildDetailRow('Address', caregiver['address'] ?? 'N/A'),
              _buildDetailRow('Bio', caregiver['bio'] ?? 'N/A'),
              _buildDetailRow('Services', (caregiver['services'] as List?)?.join(', ') ?? 'N/A'),
              const SizedBox(height: 16),
              Text(
                'Verification Status: ${caregiver['verificationStatus'] ?? 'pending'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if ((caregiver['verificationStatus'] ?? 'pending') == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AdminRoutes.adminVerifications);
              },
              child: const Text('Review Verification'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _quickApprove(Map<String, dynamic> caregiver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Approve Caregiver'),
        content: Text(
          'Are you sure you want to approve ${caregiver['fullName']}?\n\n'
          'This will verify their account without reviewing documents. '
          'It is recommended to review verification requests properly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Update user status
      final success = await _adminService.updateUserStatus(caregiver['id'], true);
      
      if (success && mounted) {
        // Also update verification status
        await FirebaseFirestore.instance
            .collection('users')
            .doc(caregiver['id'])
            .update({
          'verificationStatus': 'approved',
          'isVerified': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${caregiver['fullName']} has been approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
