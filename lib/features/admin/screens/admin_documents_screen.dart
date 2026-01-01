import 'package:flutter/material.dart';
import '../widgets/document_card.dart';
import '../services/admin_document_service.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  final _documentService = AdminDocumentService();
  String _selectedType = 'all';
  String _searchQuery = '';
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await _documentService.getDocumentStatistics();
    if (mounted) {
      setState(() {
        _statistics = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatistics(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          SizedBox(
            height: MediaQuery.of(context).size.height - 350,
            child: _buildDocumentsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final totalDocs = _statistics['totalDocuments'] ?? 0;
    final totalSize = _statistics['totalSize'] ?? 0;
    final sizeFormatted = _documentService.formatFileSize(totalSize);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatCard(
              icon: Icons.description,
              label: 'Total Documents',
              value: totalDocs.toString(),
              color: Colors.blue,
            ),
            const SizedBox(width: 24),
            _buildStatCard(
              icon: Icons.storage,
              label: 'Total Storage',
              value: sizeFormatted,
              color: Colors.purple,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDocumentsByType(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsByType() {
    final docsByType = _statistics['documentsByType'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documents by Type',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docsByType.entries.map((entry) {
            return Chip(
              label: Text('${_documentService.getDocumentTypeLabel(entry.key)}: ${entry.value}'),
              avatar: const Icon(Icons.folder, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by filename or user ID...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Filter by Type:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'id_proof', child: Text('ID Proof')),
                DropdownMenuItem(value: 'address_proof', child: Text('Address Proof')),
                DropdownMenuItem(value: 'certifications', child: Text('Certifications')),
                DropdownMenuItem(value: 'background_check', child: Text('Background Check')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _documentService.getAllDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var documents = snapshot.data ?? [];

        // Apply type filter
        if (_selectedType != 'all') {
          documents = documents.where((doc) {
            return doc['documentType'] == _selectedType;
          }).toList();
        }

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          documents = documents.where((doc) {
            final fileName = (doc['fileName'] ?? '').toString().toLowerCase();
            final userId = (doc['userId'] ?? '').toString().toLowerCase();
            return fileName.contains(_searchQuery) || userId.contains(_searchQuery);
          }).toList();
        }

        if (documents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No documents found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getGridCount(context),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            return DocumentCard(
              document: document,
              showUserInfo: true,
            );
          },
        );
      },
    );
  }

  int _getGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
