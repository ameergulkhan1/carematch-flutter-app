import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClientNearbyCaregiversMap extends StatefulWidget {
  final List<LatLng> caregiverLocations;
  final LatLng? clientLocation;

  const ClientNearbyCaregiversMap({
    super.key,
    required this.caregiverLocations,
    this.clientLocation,
  });

  @override
  State<ClientNearbyCaregiversMap> createState() => _ClientNearbyCaregiversMapState();
}

class _ClientNearbyCaregiversMapState extends State<ClientNearbyCaregiversMap> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      if (widget.clientLocation != null)
        Marker(
          markerId: const MarkerId('client'),
          position: widget.clientLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      ...widget.caregiverLocations.asMap().entries.map((entry) => Marker(
            markerId: MarkerId('caregiver_${entry.key}'),
            position: entry.value,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Caregiver ${entry.key + 1}'),
          )),
    };

    final LatLng initialPosition = widget.clientLocation ?? 
        (widget.caregiverLocations.isNotEmpty 
            ? widget.caregiverLocations.first 
            : const LatLng(37.42796133580664, -122.085749655962));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                // Fit bounds to show all markers
                if (markers.length > 1) {
                  _fitBounds(markers);
                }
              },
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 12,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: !isSmallScreen,
              zoomControlsEnabled: !isSmallScreen,
              compassEnabled: true,
              mapToolbarEnabled: false,
              mapType: MapType.normal,
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              minMaxZoomPreference: const MinMaxZoomPreference(10, 18),
            ),
          ),
        );
      },
    );
  }

  void _fitBounds(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;

    final bounds = _calculateBounds(markers.map((m) => m.position).toList());
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var position in positions) {
      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
