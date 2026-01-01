import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/caregiver_search_service.dart';
import '../../../models/caregiver_user_model.dart';
import 'dashboard/client_colors.dart';
import 'caregiver_profile_view.dart';

class SavedCaregiversScreen extends StatefulWidget {
  const SavedCaregiversScreen({super.key});

  @override
  State<SavedCaregiversScreen> createState() => _SavedCaregiversScreenState();
}

class _SavedCaregiversScreenState extends State<SavedCaregiversScreen> {
  final CaregiverSearchService _searchService = CaregiverSearchService();
  List<CaregiverUser> _savedCaregivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCaregivers();
  }

  Future<void> _loadSavedCaregivers() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.uid;

      if (userId != null) {
        final caregivers = await _searchService.getFavoriteCaregivers(userId);
        setState(() {
          _savedCaregivers = caregivers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading saved caregivers: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved Caregivers',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ClientColors.dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_savedCaregivers.length} caregivers saved',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (!_isLoading)
                IconButton(
                  onPressed: _loadSavedCaregivers,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _savedCaregivers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadSavedCaregivers,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _savedCaregivers.length,
                        itemBuilder: (context, index) {
                          return _buildCaregiverCard(_savedCaregivers[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCaregiverCard(CaregiverUser caregiver) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewCaregiverProfile(caregiver),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: ClientColors.primary.withOpacity(0.1),
                    child: Text(
                      caregiver.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () => _removeFavorite(caregiver),
                      icon: const Icon(
                        Icons.favorite,
                        color: ClientColors.danger,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                caregiver.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ClientColors.dark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (caregiver.specializations.isNotEmpty)
                Text(
                  caregiver.specializations.first,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(caregiver.verificationStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(caregiver.verificationStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(caregiver.verificationStatus),
                  ),
                ),
              ),
              if (caregiver.yearsOfExperience != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: ClientColors.info),
                    const SizedBox(width: 4),
                    Text(
                      '${caregiver.yearsOfExperience} years exp.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _viewCaregiverProfile(caregiver),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClientColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved caregivers yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ClientColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse caregivers and save your favorites',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to search caregivers
            },
            icon: const Icon(Icons.search),
            label: const Text('Find Caregivers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewCaregiverProfile(CaregiverUser caregiver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverProfileView(caregiver: caregiver),
      ),
    );
  }

  Future<void> _removeFavorite(CaregiverUser caregiver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: Text('Remove ${caregiver.fullName} from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClientColors.danger,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.uid;

        if (userId != null) {
          await _searchService.removeCaregiverFromFavorites(userId, caregiver.uid);
          _loadSavedCaregivers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${caregiver.fullName} removed from favorites'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return ClientColors.success;
      case 'pending':
        return ClientColors.warning;
      case 'rejected':
        return ClientColors.danger;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Not Verified';
      default:
        return status;
    }
  }
}
