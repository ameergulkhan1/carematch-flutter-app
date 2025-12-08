import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/caregiver_search_service.dart';
import '../../../models/caregiver_user_model.dart';
import '../../../providers/auth_provider.dart';
import 'caregiver_profile_view.dart';

class SearchCaregiversScreen extends StatefulWidget {
  const SearchCaregiversScreen({super.key});

  @override
  State<SearchCaregiversScreen> createState() => _SearchCaregiversScreenState();
}

class _SearchCaregiversScreenState extends State<SearchCaregiversScreen> {
  final CaregiverSearchService _searchService = CaregiverSearchService();
  final TextEditingController _searchController = TextEditingController();
  
  List<CaregiverUser> _allCaregivers = [];
  List<CaregiverUser> _filteredCaregivers = [];
  Set<String> _favoriteCaregiverIds = {};
  bool _isLoading = true;
  bool _showFilters = false;
  
  // Filter values
  final List<String> _selectedServices = [];
  int? _minExperience;
  String? _selectedCity;
  String _sortBy = 'rating'; // rating, experience, rate
  
  // Available filter options
  final List<String> _availableServices = [
    'Child Care',
    'Elderly Care',
    'Special Needs Care',
    'Medical Care',
    'Companionship',
    'Personal Care',
    'Respite Care',
    'Live-in Care'
  ];
  
  final List<String> _availableCities = [
    'New York',
    'Los Angeles',
    'Chicago',
    'Houston',
    'Phoenix',
    'Philadelphia',
    'San Antonio',
    'San Diego'
  ];

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
    _loadFavorites();
  }

  Future<void> _loadCaregivers() async {
    setState(() => _isLoading = true);
    try {
      final caregivers = await _searchService.getVerifiedCaregivers();
      setState(() {
        _allCaregivers = caregivers;
        _filteredCaregivers = caregivers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading caregivers: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;
    if (userId != null) {
      final favorites = await _searchService.getFavoriteCaregivers(userId);
      setState(() {
        _favoriteCaregiverIds = favorites.map((c) => c.uid).toSet();
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCaregivers = _allCaregivers.where((caregiver) {
        // Search text filter
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          if (!caregiver.fullName.toLowerCase().contains(searchLower) &&
              !caregiver.specializations.any((s) => s.toLowerCase().contains(searchLower))) {
            return false;
          }
        }

        // Service filter
        if (_selectedServices.isNotEmpty) {
          if (!_selectedServices.any((s) => caregiver.specializations.contains(s))) {
            return false;
          }
        }

        // Experience filter
        if (_minExperience != null && caregiver.yearsOfExperience != null) {
          final experience = int.tryParse(caregiver.yearsOfExperience!) ?? 0;
          if (experience < _minExperience!) {
            return false;
          }
        }

        // City filter
        if (_selectedCity != null && _selectedCity!.isNotEmpty) {
          if (caregiver.city.toLowerCase() != _selectedCity!.toLowerCase()) {
            return false;
          }
        }

        return true;
      }).toList();

      // Apply sorting
      _filteredCaregivers.sort((a, b) {
        switch (_sortBy) {
          case 'experience':
            final expA = int.tryParse(a.yearsOfExperience ?? '0') ?? 0;
            final expB = int.tryParse(b.yearsOfExperience ?? '0') ?? 0;
            return expB.compareTo(expA);
          case 'newest':
            return b.createdAt.compareTo(a.createdAt);
          default: // rating or default
            // For now, sort by verification status and creation date
            if (a.verificationStatus == 'approved' && b.verificationStatus != 'approved') return -1;
            if (b.verificationStatus == 'approved' && a.verificationStatus != 'approved') return 1;
            return b.createdAt.compareTo(a.createdAt);
        }
      });
    });
  }

  Future<void> _toggleFavorite(String caregiverId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save favorites')),
      );
      return;
    }

    final isFavorite = _favoriteCaregiverIds.contains(caregiverId);
    
    if (isFavorite) {
      await _searchService.removeCaregiverFromFavorites(userId, caregiverId);
      setState(() => _favoriteCaregiverIds.remove(caregiverId));
    } else {
      await _searchService.saveCaregiverToFavorites(userId, caregiverId);
      setState(() => _favoriteCaregiverIds.add(caregiverId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Caregivers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFilterPanel(),
          _buildResultsHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCaregivers.isEmpty
                    ? _buildEmptyState()
                    : _buildCaregiverGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or service...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        onChanged: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          
          // Services filter
          Text('Services', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableServices.map((service) {
              final isSelected = _selectedServices.contains(service);
              return FilterChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service);
                    } else {
                      _selectedServices.remove(service);
                    }
                  });
                  _applyFilters();
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // City filter
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('City', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('All Cities'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Cities')),
                        ..._availableCities.map((city) => DropdownMenuItem(value: city, child: Text(city))),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCity = value);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Min. Experience', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _minExperience,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Any'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Any')),
                        DropdownMenuItem(value: 1, child: Text('1+ years')),
                        DropdownMenuItem(value: 3, child: Text('3+ years')),
                        DropdownMenuItem(value: 5, child: Text('5+ years')),
                        DropdownMenuItem(value: 10, child: Text('10+ years')),
                      ],
                      onChanged: (value) {
                        setState(() => _minExperience = value);
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Clear filters button
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedServices.clear();
                  _selectedCity = null;
                  _minExperience = null;
                  _searchController.clear();
                });
                _applyFilters();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredCaregivers.length} Caregivers Found',
            style: AppTextStyles.titleSmall,
          ),
          Row(
            children: [
              Text('Sort by:', style: AppTextStyles.bodySmall),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortBy,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'rating', child: Text('Best Match')),
                  DropdownMenuItem(value: 'experience', child: Text('Experience')),
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                ],
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('No caregivers found', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine number of columns based on width
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 768) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: constraints.maxWidth < 768 ? 0.85 : 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _filteredCaregivers.length,
          itemBuilder: (context, index) {
            final caregiver = _filteredCaregivers[index];
            final isFavorite = _favoriteCaregiverIds.contains(caregiver.uid);
            return _buildCaregiverCard(caregiver, isFavorite);
          },
        );
      },
    );
  }

  Widget _buildCaregiverCard(CaregiverUser caregiver, bool isFavorite) {
    final experience = int.tryParse(caregiver.yearsOfExperience ?? '0') ?? 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaregiverProfileView(caregiver: caregiver),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and favorite button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      caregiver.fullName[0].toUpperCase(),
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiver.fullName,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${caregiver.city}, ${caregiver.state}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : AppColors.textSecondary,
                    ),
                    onPressed: () => _toggleFavorite(caregiver.uid),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Experience
                    Row(
                      children: [
                        const Icon(Icons.work_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$experience years experience',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Specializations
                    if (caregiver.specializations.isNotEmpty) ...[
                      Text('Specializations:', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: caregiver.specializations.take(3).map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              spec,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (caregiver.specializations.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${caregiver.specializations.length - 3} more',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                    
                    const Spacer(),
                    
                    // Verification badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: caregiver.verificationStatus == 'approved'
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            caregiver.verificationStatus == 'approved'
                                ? Icons.verified
                                : Icons.pending,
                            size: 14,
                            color: caregiver.verificationStatus == 'approved'
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            caregiver.verificationStatus == 'approved'
                                ? 'Verified'
                                : 'Pending',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: caregiver.verificationStatus == 'approved'
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // View Profile button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Text(
                'View Full Profile →',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
