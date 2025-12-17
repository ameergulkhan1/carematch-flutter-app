import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/responsive_utils.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;

  const LocationPickerMap({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location services are disabled. Please enable them.');
        setState(() => _isLoadingCurrentLocation = false);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Location permission denied');
          setState(() => _isLoadingCurrentLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('Location permissions are permanently denied');
        setState(() => _isLoadingCurrentLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = currentLocation;
        _isLoadingCurrentLocation = false;
      });

      // Animate camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );

      widget.onLocationSelected(currentLocation);
    } catch (e) {
      _showMessage('Error getting location: ${e.toString()}');
      setState(() => _isLoadingCurrentLocation = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final initialPosition = _selectedLocation ??
        widget.initialLocation ??
        const LatLng(37.7749, -122.4194); // Default: San Francisco

    return Column(
      children: [
        // Instructions
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: isMobile ? 20 : 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap on the map to set your location or use current location',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getFontSize(context,
                        mobile: 13, tablet: 14, desktop: 15),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Map
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 14,
                ),
                onTap: (LatLng location) {
                  setState(() => _selectedLocation = location);
                  widget.onLocationSelected(location);
                },
                markers: _selectedLocation != null
                    ? {
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: _selectedLocation!,
                          draggable: true,
                          onDragEnd: (newPosition) {
                            setState(() => _selectedLocation = newPosition);
                            widget.onLocationSelected(newPosition);
                          },
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen,
                          ),
                          infoWindow: const InfoWindow(
                            title: 'Your Location',
                            snippet: 'Drag to adjust',
                          ),
                        ),
                      }
                    : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: !isMobile,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),

              // Current Location Button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _isLoadingCurrentLocation ? null : _getCurrentLocation,
                  backgroundColor: AppColors.primary,
                  child: _isLoadingCurrentLocation
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                ),
              ),
            ],
          ),
        ),

        // Selected Location Info
        if (_selectedLocation != null)
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.getContentPadding(context)),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: isMobile ? 20 : 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Selected',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context,
                              mobile: 13, tablet: 14, desktop: 15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context,
                              mobile: 11, tablet: 12, desktop: 13),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
