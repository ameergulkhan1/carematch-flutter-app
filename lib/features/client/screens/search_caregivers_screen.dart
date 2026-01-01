import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/caregiver_search_service.dart';
import '../../../models/caregiver_user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../widgets/caregiver_filter_panel.dart';
import '../widgets/client_nearby_caregivers_map.dart';
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
  bool _showMap = false;

  // Filter values
  final List<String> _selectedServices = [];
  int? _minExperience;
  String? _selectedCity;

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
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          if (!caregiver.fullName.toLowerCase().contains(searchLower) &&
              !caregiver.specializations
                  .any((s) => s.toLowerCase().contains(searchLower))) {
            return false;
          }
        }

        if (_selectedServices.isNotEmpty) {
          if (!_selectedServices
              .any((s) => caregiver.specializations.contains(s))) {
            return false;
          }
        }

        if (_minExperience != null && caregiver.yearsOfExperience != null) {
          final experience = int.tryParse(caregiver.yearsOfExperience!) ?? 0;
          if (experience < _minExperience!) {
            return false;
          }
        }

        if (_selectedCity != null && _selectedCity!.isNotEmpty) {
          if (caregiver.city.toLowerCase() != _selectedCity!.toLowerCase()) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(String caregiverId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save favorites')),
      );
      return;
    }

    if (_favoriteCaregiverIds.contains(caregiverId)) {
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
        title: Text(
          'Find Caregivers',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context,
                mobile: 18, tablet: 20, desktop: 22),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(child: _buildSearchBar()),
          
          // Filter and Map Buttons
          SliverToBoxAdapter(child: _buildActionButtons()),
          
          // Filter Panel (collapsible)
          if (_showFilters)
            SliverToBoxAdapter(child: _buildFilterPanel()),
          
          // Map (collapsible)
          if (_showMap)
            SliverToBoxAdapter(child: _buildMapSection()),
          
          // Results Header
          SliverToBoxAdapter(child: _buildResultsHeader()),
          
          // Loading or Empty State or Grid
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredCaregivers.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState())
                  : _buildCaregiverSliverGrid(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or service...',
          hintStyle: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context,
                mobile: 14, tablet: 15, desktop: 16),
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (_) => _applyFilters(),
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasActiveFilters = _selectedServices.isNotEmpty ||
        _minExperience != null ||
        _selectedCity != null;
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getContentPadding(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          // Filter Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_alt,
                size: isMobile ? 18 : 20,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _showFilters ? 'Hide Filters' : 'Filters',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context,
                            mobile: 13, tablet: 14, desktop: 15),
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_selectedServices.length + (_minExperience != null ? 1 : 0) + (_selectedCity != null ? 1 : 0))}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context,
                              mobile: 11, tablet: 12, desktop: 13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasActiveFilters 
                    ? AppColors.primary 
                    : AppColors.primary.withOpacity(0.9),
                foregroundColor: Colors.white,
                elevation: hasActiveFilters ? 4 : 2,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Map Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showMap = !_showMap),
              icon: Icon(
                _showMap ? Icons.map_outlined : Icons.map,
                size: isMobile ? 18 : 20,
              ),
              label: Text(
                _showMap ? 'Hide Map' : 'Map View',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context,
                      mobile: 13, tablet: 14, desktop: 15),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showMap 
                    ? AppColors.success 
                    : AppColors.success.withOpacity(0.9),
                foregroundColor: Colors.white,
                elevation: _showMap ? 4 : 2,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return CaregiverFilterPanel(
      selectedServices: _selectedServices,
      minExperience: _minExperience,
      selectedCity: _selectedCity,
      availableServices: _availableServices,
      availableCities: _availableCities,
      onClearFilters: () {
        setState(() {
          _selectedServices.clear();
          _minExperience = null;
          _selectedCity = null;
          _searchController.clear();
        });
        _applyFilters();
      },
      onServicesChanged: (services) {
        setState(() {
          _selectedServices.clear();
          _selectedServices.addAll(services);
        });
        _applyFilters();
      },
      onExperienceChanged: (experience) {
        setState(() => _minExperience = experience);
        _applyFilters();
      },
      onCityChanged: (city) {
        setState(() => _selectedCity = city);
        _applyFilters();
      },
    );
  }

  Widget _buildMapSection() {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Get locations from filtered caregivers
    List<LatLng> caregiverLocations = _filteredCaregivers
        .where((c) => c.latitude != null && c.longitude != null)
        .map((c) => LatLng(c.latitude!, c.longitude!))
        .toList();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: isMobile ? 20 : 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nearby Caregivers',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context,
                        mobile: 16, tablet: 17, desktop: 18),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: isMobile ? 300 : 400,
            child: caregiverLocations.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: isMobile ? 48 : 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No location data available',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context,
                                  mobile: 14, tablet: 15, desktop: 16),
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ClientNearbyCaregiversMap(
                    caregiverLocations: caregiverLocations,
                    clientLocation: null, // Can be set if client location is available
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getContentPadding(context),
        vertical: 12,
      ),
      child: Text(
        '${_filteredCaregivers.length} ${_filteredCaregivers.length == 1 ? 'Caregiver' : 'Caregivers'} Found',
        style: TextStyle(
          fontSize: ResponsiveUtils.getFontSize(context,
              mobile: 14, tablet: 15, desktop: 16),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: ResponsiveUtils.isMobile(context) ? 64 : 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Caregivers Found',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 18, tablet: 20, desktop: 22),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context,
                    mobile: 14, tablet: 15, desktop: 16),
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverSliverGrid() {
    return SliverPadding(
      padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getGridColumns(
            context,
            mobile: 1,
            tablet: 2,
            desktop: 3,
          ),
          childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.05 : 0.88,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final caregiver = _filteredCaregivers[index];
            final isFavorite = _favoriteCaregiverIds.contains(caregiver.uid);
            return _buildCaregiverCard(caregiver, isFavorite);
          },
          childCount: _filteredCaregivers.length,
        ),
      ),
    );
  }

  Widget _buildCaregiverCard(CaregiverUser caregiver, bool isFavorite) {
    final experience = int.tryParse(caregiver.yearsOfExperience ?? '0') ?? 0;
    final isVerified = caregiver.verificationStatus == 'approved';
    final isMobile = ResponsiveUtils.isMobile(context);

    return Card(
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaregiverProfileView(caregiver: caregiver),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.getCardPadding(context)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.primary.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isVerified
                            ? AppColors.success
                            : AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: isMobile ? 28 : 32,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        caregiver.fullName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context,
                              mobile: 20, tablet: 22, desktop: 24),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name and Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                caregiver.fullName,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context,
                                      mobile: 15, tablet: 16, desktop: 17),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified)
                              Tooltip(
                                message: 'Verified Caregiver',
                                child: Icon(
                                  Icons.verified,
                                  size: isMobile ? 16 : 18,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: isMobile ? 13 : 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${caregiver.city}, ${caregiver.state}',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context,
                                      mobile: 12, tablet: 13, desktop: 14),
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Favorite Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleFavorite(caregiver.uid),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.error
                              : AppColors.textSecondary,
                          size: isMobile ? 20 : 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveUtils.getCardPadding(context)),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Experience Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: isMobile ? 14 : 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$experience ${experience == 1 ? 'Year' : 'Years'} Experience',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context,
                                  mobile: 12, tablet: 13, desktop: 14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bio Preview
                    if (caregiver.bio != null && caregiver.bio!.isNotEmpty) ...[
                      Text(
                        caregiver.bio!,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context,
                              mobile: 12, tablet: 13, desktop: 14),
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Specializations
                    if (caregiver.specializations.isNotEmpty) ...[
                      Text(
                        'Specializations',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context,
                              mobile: 11, tablet: 12, desktop: 13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: caregiver.specializations.take(3).map((spec) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              spec,
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context,
                                    mobile: 10, tablet: 11, desktop: 12),
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (caregiver.specializations.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+${caregiver.specializations.length - 3} more',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context,
                                  mobile: 10, tablet: 11, desktop: 12),
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            // View Profile Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CaregiverProfileView(caregiver: caregiver),
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Full Profile',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getFontSize(context,
                                mobile: 13, tablet: 14, desktop: 15),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: isMobile ? 16 : 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
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
