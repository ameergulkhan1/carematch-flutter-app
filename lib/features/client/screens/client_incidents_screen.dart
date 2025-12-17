import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import 'dashboard/client_colors.dart';

class ClientIncidentsScreen extends StatefulWidget {
  const ClientIncidentsScreen({super.key});

  @override
  State<ClientIncidentsScreen> createState() => _ClientIncidentsScreenState();
}

class _ClientIncidentsScreenState extends State<ClientIncidentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus =
      'all'; // all, submitted, investigating, resolved, closed

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.currentUser?.uid;

    return Scaffold(
      backgroundColor: ClientColors.background,
      body: Column(
        children: [
          // Header with stats and filters
          Container(
            padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ClientColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.report_problem,
                          color: ClientColors.warning, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incidents & Reports',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ClientColors.dark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track your incident reports and resolutions',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', Icons.list),
                      const SizedBox(width: 8),
                      _buildFilterChip('Submitted', 'submitted', Icons.send),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Investigating', 'investigating', Icons.search),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                          'Resolved', 'resolved', Icons.check_circle),
                      const SizedBox(width: 8),
                      _buildFilterChip('Closed', 'closed', Icons.lock),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Incidents list
          Expanded(
            child: userId == null
                ? const Center(child: Text('Please login to view incidents'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _getIncidentsStream(userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      final incidents = snapshot.data?.docs ?? [];

                      if (incidents.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filterStatus == 'all'
                                    ? 'No incidents reported'
                                    : 'No ${_filterStatus} incidents',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your incident reports will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: incidents.length,
                        itemBuilder: (context, index) {
                          final incident =
                              incidents[index].data() as Map<String, dynamic>;
                          final incidentId = incidents[index].id;
                          return _buildIncidentCard(incident, incidentId);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getIncidentsStream(String userId) {
    Query query = _firestore
        .collection('incidents')
        .where('reporterId', isEqualTo: userId)
        .orderBy('reportedAt', descending: true);

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    return query.snapshots();
  }

  Widget _buildFilterChip(String label, String status, IconData icon) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: isSelected ? ClientColors.primary : Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      backgroundColor: Colors.white,
      selectedColor: ClientColors.primary.withOpacity(0.1),
      checkmarkColor: ClientColors.primary,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? ClientColors.primary : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? ClientColors.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident, String incidentId) {
    final incidentNumber = incident['incidentNumber'] ?? 'N/A';
    final type = incident['type'] ?? 'unknown';
    final status = incident['status'] ?? 'submitted';
    final severity = incident['severity'] ?? 'medium';
    final title = incident['title'] ?? 'Incident Report';
    final description = incident['description'] ?? '';
    final caregiverName = incident['caregiverName'] ?? 'Unknown';
    final reportedAt = (incident['reportedAt'] as Timestamp?)?.toDate();
    final resolvedAt = (incident['resolvedAt'] as Timestamp?)?.toDate();
    final tags = (incident['tags'] as List?)?.cast<String>() ?? [];

    final statusColor = _getStatusColor(status);
    final typeIcon = _getTypeIcon(type);
    final severityColor = _getSeverityColor(severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severity == 'high'
              ? ClientColors.danger.withOpacity(0.3)
              : Colors.grey.shade200,
          width: severity == 'high' ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(typeIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            incidentNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ClientColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              severity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: severityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ClientColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caregiver info
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Caregiver: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      caregiverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ClientColors.dark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Type
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Type: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatType(type),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ClientColors.dark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ClientColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tags
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ClientColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: ClientColors.info,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Timestamps
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Reported: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      reportedAt != null
                          ? DateFormat('MMM dd, yyyy').format(reportedAt)
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (resolvedAt != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Resolved: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(resolvedAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action button (if needed)
          if (status == 'submitted' || status == 'investigating')
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == 'investigating'
                          ? 'Admin is reviewing your report. You\'ll be notified of updates.'
                          : 'Your report has been received and will be reviewed shortly.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'investigating':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'noShow':
        return Icons.person_off;
      case 'lateArrival':
        return Icons.access_time;
      case 'paymentDispute':
        return Icons.payment;
      case 'clientComplaint':
        return Icons.report_problem;
      case 'behaviorIssue':
        return Icons.psychology;
      default:
        return Icons.report;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'investigating':
        return 'Investigating';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String _formatType(String type) {
    switch (type) {
      case 'noShow':
        return 'No Show';
      case 'lateArrival':
        return 'Late Arrival';
      case 'paymentDispute':
        return 'Payment Dispute';
      case 'clientComplaint':
        return 'Client Complaint';
      case 'behaviorIssue':
        return 'Behavior Issue';
      default:
        return type;
    }
  }
}
