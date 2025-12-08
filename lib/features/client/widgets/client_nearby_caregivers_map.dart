import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClientNearbyCaregiversMap extends StatelessWidget {
  final List<LatLng> caregiverLocations;
  final LatLng? clientLocation;

  const ClientNearbyCaregiversMap({
    super.key,
    required this.caregiverLocations,
    this.clientLocation,
  });

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {
      if (clientLocation != null)
        Marker(
          markerId: const MarkerId('client'),
          position: clientLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      ...caregiverLocations.asMap().entries.map((entry) => Marker(
            markerId: MarkerId('caregiver_${entry.key}'),
            position: entry.value,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Caregiver'),
          )),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: clientLocation ?? (caregiverLocations.isNotEmpty ? caregiverLocations.first : const LatLng(37.42796133580664, -122.085749655962)),
              zoom: 13,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: constraints.maxWidth > 400,
            mapType: MapType.normal,
          ),
        );
      },
    );
  }
}
