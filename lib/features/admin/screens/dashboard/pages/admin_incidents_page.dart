import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../models/incident_report_model.dart';
import '../../../../../services/incident_service.dart';

class AdminIncidentsPage extends StatefulWidget {
  const AdminIncidentsPage({super.key});

  @override
  State<AdminIncidentsPage> createState() => _AdminIncidentsPageState();
}

class _AdminIncidentsPageState extends State<AdminIncidentsPage> {
  final IncidentService _incidentService = IncidentService();

  IncidentStatus? _statusFilter;
  IncidentSeverity? _severityFilter;
  IncidentType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCriticalAlertsSection(),
          _buildStatsSection(),
          _buildFilterChips(),
          Expanded(child: _buildIncidentsList()),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsSection() {
    return StreamBuilder<List<IncidentReport>>(
      stream: _incidentService.getCriticalIncidents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.red[100],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${snapshot.data!.length} Critical Incident(s) Require Immediate Attention',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _incidentService.getIncidentStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total',
                stats['total'].toString(),
                Icons.list_alt,
                Colors.blue,
              ),
              _buildStatCard(
                'Pending',
                stats['pending'].toString(),
                Icons.pending_actions,
                Colors.orange,
              ),
              _buildStatCard(
                'Critical',
                stats['critical'].toString(),
                Icons.warning,
                Colors.red,
              ),
              _buildStatCard(
                'Resolved',
                stats['resolved'].toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final hasFilters = _statusFilter != null ||
        _severityFilter != null ||
        _typeFilter != null;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_statusFilter != null)
            Chip(
              label: Text('Status: ${_statusFilter!.name}'),
              onDeleted: () => setState(() => _statusFilter = null),
            ),
          if (_severityFilter != null)
            Chip(
              label: Text('Severity: ${_severityFilter!.name}'),
              onDeleted: () => setState(() => _severityFilter = null),
            ),
          if (_typeFilter != null)
            Chip(
              label: Text('Type: ${_typeFilter!.name}'),
              onDeleted: () => setState(() => _typeFilter = null),
            ),
          TextButton(
            onPressed: () => setState(() {
              _statusFilter = null;
              _severityFilter = null;
              _typeFilter = null;
            }),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsList() {
    return StreamBuilder<List<IncidentReport>>(
      stream: _incidentService.getIncidents(
        status: _statusFilter,
        severity: _severityFilter,
        type: _typeFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final incidents = snapshot.data ?? [];

        if (incidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No incidents found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            return _buildIncidentCard(incidents[index]);
          },
        );
      },
    );
  }

  Widget _buildIncidentCard(IncidentReport incident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showIncidentDetails(incident),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(incident.severity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incident.severity.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(incident.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incident.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    incident.incidentNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                incident.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Reporter: ${incident.reporterName}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy').format(incident.incidentDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (incident.evidence.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${incident.evidence.length} Evidence File(s)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(IncidentReport incident) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncidentDetailsScreen(incident: incident),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Incidents'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status:'),
                DropdownButton<IncidentStatus?>(
                  value: _statusFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...IncidentStatus.values.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name))),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
                const SizedBox(height: 16),
                const Text('Severity:'),
                DropdownButton<IncidentSeverity?>(
                  value: _severityFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ...IncidentSeverity.values.map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name))),
                  ],
                  onChanged: (value) => setState(() => _severityFilter = value),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.blue;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.deepOrange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.submitted:
        return Colors.orange;
      case IncidentStatus.underReview:
        return Colors.blue;
      case IncidentStatus.investigating:
        return Colors.purple;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.dismissed:
        return Colors.grey[700]!;
      case IncidentStatus.escalated:
        return Colors.red;
    }
  }
}

// Incident Details Screen
class IncidentDetailsScreen extends StatefulWidget {
  final IncidentReport incident;

  const IncidentDetailsScreen({super.key, required this.incident});

  @override
  State<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends State<IncidentDetailsScreen> {
  final IncidentService _incidentService = IncidentService();
  final _notesController = TextEditingController();
  final _resolutionController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incident.incidentNumber),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              if (widget.incident.status == IncidentStatus.submitted)
                const PopupMenuItem(
                  value: 'investigate',
                  child: Text('Start Investigation'),
                ),
              if (widget.incident.status == IncidentStatus.investigating ||
                  widget.incident.status == IncidentStatus.underReview)
                const PopupMenuItem(
                  value: 'resolve',
                  child: Text('Resolve Incident'),
                ),
              if (widget.incident.severity != IncidentSeverity.critical)
                const PopupMenuItem(
                  value: 'escalate',
                  child: Text('Escalate to Critical'),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
          const SizedBox(height: 24),
          _buildParticipantsSection(),
          const SizedBox(height: 24),
          _buildEvidenceSection(),
          const SizedBox(height: 24),
          _buildTimelineSection(),
          const SizedBox(height: 24),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: _getSeverityColor(widget.incident.severity).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(widget.incident.severity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.incident.severity.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.incident.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.incident.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.incident.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reported: ${DateFormat('MMM d, yyyy HH:mm').format(widget.incident.reportedAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.incident.description),
            const Divider(height: 24),
            _buildInfoRow('Type', widget.incident.type.name),
            _buildInfoRow(
              'Incident Date',
              DateFormat('MMM d, yyyy').format(widget.incident.incidentDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Participants',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Reporter', widget.incident.reporterName),
            if (widget.incident.caregiverName != null)
              _buildInfoRow('Caregiver', widget.incident.caregiverName!),
            if (widget.incident.clientName != null)
              _buildInfoRow('Client', widget.incident.clientName!),
            if (widget.incident.assignedToName != null)
              _buildInfoRow(
                  'Assigned To', widget.incident.assignedToName!),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    if (widget.incident.evidence.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evidence (${widget.incident.evidence.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.incident.evidence.map((evidence) {
              return ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(evidence.fileName),
                subtitle: Text(
                  'Uploaded by ${evidence.uploadedBy} on ${DateFormat('MMM d, yyyy').format(evidence.uploadedAt)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // Open/download evidence
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Investigation Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.incident.timeline.isEmpty)
              Text('No timeline entries yet',
                  style: TextStyle(color: Colors.grey[600])),
            ...widget.incident.timeline.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.action,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (entry.notes != null) Text(entry.notes!),
                          Text(
                            '${entry.performedBy} - ${DateFormat('MMM d, HH:mm').format(entry.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Add Investigation Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addNotes,
              child: const Text('Add Notes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'investigate':
        _startInvestigation();
        break;
      case 'resolve':
        _showResolveDialog();
        break;
      case 'escalate':
        _escalateIncident();
        break;
    }
  }

  Future<void> _addNotes() async {
    if (_notesController.text.trim().isEmpty) return;

    try {
      await _incidentService.addInvestigationNotes(
        incidentId: widget.incident.id,
        notes: _notesController.text.trim(),
        performedBy: 'admin_id', // Get from auth
        performedByName: 'Admin', // Get from auth
      );

      _notesController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding notes: $e')),
        );
      }
    }
  }

  Future<void> _startInvestigation() async {
    try {
      await _incidentService.assignIncident(
        incidentId: widget.incident.id,
        assignedTo: 'current_admin_id', // Get from auth
        assignedToName: 'Current Admin',
        assignedBy: 'current_admin_id', // Get from auth
        assignedByName: 'Current Admin',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Investigation started')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showResolveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Incident'),
        content: TextField(
          controller: _resolutionController,
          decoration: const InputDecoration(
            labelText: 'Resolution Summary',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _resolveIncident();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveIncident() async {
    try {
      await _incidentService.resolveIncident(
        incidentId: widget.incident.id,
        resolutionNotes: _resolutionController.text.trim(),
        resolvedBy: 'admin_id',
        resolvedByName: 'Admin',
        actionTaken: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident resolved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _escalateIncident() async {
    try {
      await _incidentService.escalateIncident(
        incidentId: widget.incident.id,
        performedBy: 'admin_id',
        performedByName: 'Admin',
        escalationReason: 'Escalated to critical severity',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident escalated')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.blue;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.deepOrange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.submitted:
        return Colors.orange;
      case IncidentStatus.underReview:
        return Colors.blue;
      case IncidentStatus.investigating:
        return Colors.purple;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.dismissed:
        return Colors.grey[700]!;
      case IncidentStatus.escalated:
        return Colors.red;
    }
  }
}
