import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CaregiverMapShare extends StatefulWidget {
  final LatLng? initialLocation;
  final void Function(LatLng) onLocationShared;

  const CaregiverMapShare({
    super.key,
    this.initialLocation,
    required this.onLocationShared,
  });

  @override
  State<CaregiverMapShare> createState() => _CaregiverMapShareState();
}

class _CaregiverMapShareState extends State<CaregiverMapShare> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialLocation ?? const LatLng(37.42796133580664, -122.085749655962),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: _onMapTap,
                  markers: _selectedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                          ),
                        },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.share_location),
              label: const Text('Share My Location'),
              onPressed: _selectedLocation == null
                  ? null
                  : () => widget.onLocationShared(_selectedLocation!),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(constraints.maxWidth > 400 ? 200 : double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }
}
