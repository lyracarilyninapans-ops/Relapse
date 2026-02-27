import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/providers/patient_profile_ui_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/utils/map_utils.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Safe Zone Map screen with status banner, info card, and recenter FAB.
class SafeZoneMapScreen extends ConsumerStatefulWidget {
  /// Whether the patient is inside the safe zone (placeholder).
  final bool isInside;

  const SafeZoneMapScreen({super.key, this.isInside = true});

  @override
  ConsumerState<SafeZoneMapScreen> createState() => _SafeZoneMapScreenState();
}

class _SafeZoneMapScreenState extends ConsumerState<SafeZoneMapScreen> {
  GoogleMapController? _mapController;

  static const LatLng _caregiverLocation = LatLng(37.7735, -122.4210);
  static const LatLng _safeZoneCenter = LatLng(37.7749, -122.4194);
  static const LatLng _patientLocation = LatLng(37.7763, -122.4177);
  static const double _safeZoneRadiusMeters = 500;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: _safeZoneCenter,
    zoom: 14.5,
  );

  Set<Marker> _markers(bool isInside) => {
        Marker(
          markerId: const MarkerId('caregiver_location'),
          position: _caregiverLocation,
          infoWindow: const InfoWindow(title: 'Caregiver'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
        const Marker(
          markerId: MarkerId('safe_zone_center'),
          position: _safeZoneCenter,
          infoWindow: InfoWindow(title: 'Safe Zone Center'),
        ),
        Marker(
          markerId: const MarkerId('patient_location'),
          position: _patientLocation,
          infoWindow: const InfoWindow(title: 'John Doe'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isInside
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
        ),
      };

  Set<Circle> get _circles => {
        Circle(
          circleId: const CircleId('safe_zone_radius'),
          center: _safeZoneCenter,
          radius: _safeZoneRadiusMeters,
          strokeColor: AppColors.primaryColor,
          strokeWidth: 2,
          fillColor: AppColors.primaryColor.withAlpha(51),
        ),
      };

  Future<void> _recenterMap() async {
    final controller = _mapController;
    if (controller == null) return;

    final bounds = boundsFromPoints([
      _caregiverLocation,
      _patientLocation,
    ]);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(safeZoneIsInsideProvider.notifier).state = widget.isInside;
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInside = ref.watch(safeZoneIsInsideProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Safe Zone Map',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_location_alt,
              color: AppColors.primaryColor,
            ),
            tooltip: 'Edit Safe Zone',
            onPressed: () {
              Navigator.pushNamed(context, Routes.safeZoneConfig);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers(isInside),
            circles: _circles,
            compassEnabled: true,
            zoomControlsEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Status banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isInside ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInside
                        ? AppColors.primaryColor
                        : AppColors.errorColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isInside ? Icons.check_circle : Icons.warning,
                      color: isInside
                          ? AppColors.primaryColor
                          : AppColors.errorColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isInside
                            ? 'John Doe is inside the safe zone'
                            : 'John Doe is OUTSIDE the safe zone',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isInside
                              ? AppColors.primaryColor
                              : AppColors.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Info card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient: John Doe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '37.7749, -122.4194',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Radius: 500 meters',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isInside ? 'Inside safe zone' : 'Outside safe zone',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GradientButtonWithIcon(
                      text: 'Modify Safe Zone',
                      icon: Icons.edit,
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.safeZoneConfig);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recenter FAB
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'safe_zone_recenter_fab',
              backgroundColor: AppColors.surfaceColor,
              onPressed: _recenterMap,
              child: const Icon(
                Icons.center_focus_strong,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
