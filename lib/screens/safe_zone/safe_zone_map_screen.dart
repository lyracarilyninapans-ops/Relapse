import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/providers/safe_zone_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/utils/map_utils.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Safe Zone Map screen with status banner, info card, and recenter FAB.
class SafeZoneMapScreen extends ConsumerStatefulWidget {
  const SafeZoneMapScreen({super.key});

  @override
  ConsumerState<SafeZoneMapScreen> createState() => _SafeZoneMapScreenState();
}

class _SafeZoneMapScreenState extends ConsumerState<SafeZoneMapScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14.5,
  );

  Set<Marker> _buildMarkers(bool isInside, LatLng? patientPos, LatLng? szCenter) {
    final markers = <Marker>{};

    if (szCenter != null) {
      markers.add(Marker(
        markerId: const MarkerId('safe_zone_center'),
        position: szCenter,
        infoWindow: const InfoWindow(title: 'Safe Zone Center'),
      ));
    }

    if (patientPos != null) {
      final patientName = ref.read(selectedPatientProvider)?.name ?? 'Patient';
      markers.add(Marker(
        markerId: const MarkerId('patient_location'),
        position: patientPos,
        infoWindow: InfoWindow(title: patientName),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isInside ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      ));
    }

    return markers;
  }

  Set<Circle> _buildCircles(LatLng? szCenter, double? radius) {
    if (szCenter == null || radius == null) return {};
    return {
      Circle(
        circleId: const CircleId('safe_zone_radius'),
        center: szCenter,
        radius: radius,
        strokeColor: AppColors.primaryColor,
        strokeWidth: 2,
        fillColor: AppColors.primaryColor.withAlpha(51),
      ),
    };
  }

  Future<void> _recenterMap(LatLng? patientPos, LatLng? szCenter) async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[];
    if (patientPos != null) points.add(patientPos);
    if (szCenter != null) points.add(szCenter);
    if (points.isEmpty) return;

    if (points.length == 1) {
      await controller
          .animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
    } else {
      final bounds = boundsFromPoints(points);
      await controller
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(selectedPatientProvider);

    if (patient == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          title: const GradientText(
            'Safe Zone Map',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: const NoPatientLinkedView(featureLabel: 'safe zone monitoring'),
      );
    }

    final szStatus = ref.watch(safeZoneStatusProvider);
    final isInside = szStatus == SafeZoneStatus.inside;
    final patientName = patient.name;

    final liveLocation = ref.watch(liveLocationProvider);
    final primaryZone = ref.watch(primarySafeZoneProvider);

    final patientPos = liveLocation.whenOrNull(
      data: (record) => record != null && record.latitude != null
          ? LatLng(record.latitude!, record.longitude!)
          : null,
    );

    final szCenter = primaryZone != null
        ? LatLng(primaryZone.centerLat, primaryZone.centerLng)
        : null;
    final szRadius = primaryZone?.radiusMeters;

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
            markers: _buildMarkers(isInside, patientPos, szCenter),
            circles: _buildCircles(szCenter, szRadius),
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
                            ? '$patientName is inside the safe zone'
                            : '$patientName is OUTSIDE the safe zone',
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
                    Text(
                      'Patient: $patientName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (szCenter != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${szCenter.latitude.toStringAsFixed(4)}, ${szCenter.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Radius: ${szRadius?.round() ?? '--'} meters',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ] else
                      const Text(
                        'No safe zone configured',
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
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54),
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
              onPressed: () => _recenterMap(patientPos, szCenter),
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
