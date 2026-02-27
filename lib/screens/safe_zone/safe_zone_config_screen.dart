import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/providers/safe_zone_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/utils/map_utils.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Safe Zone Configuration screen with map, radius slider, settings, event logs.
class SafeZoneConfigScreen extends ConsumerStatefulWidget {
  const SafeZoneConfigScreen({super.key});

  @override
  ConsumerState<SafeZoneConfigScreen> createState() =>
      _SafeZoneConfigScreenState();
}

class _SafeZoneConfigScreenState extends ConsumerState<SafeZoneConfigScreen> {
  GoogleMapController? _mapController;
  double _radius = 500;
  bool _locationSelected = false;
  String _watchBehavior = 'vibrate';
  bool _alertOnExit = true;
  bool _offlineMapsConfirmed = false;
  LatLng _safeZoneCenter = const LatLng(37.7749, -122.4194);
  bool _isSaving = false;
  bool _initialized = false;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 14,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Load existing safe zone into local state
      final zone = ref.read(primarySafeZoneProvider);
      if (zone != null) {
        _safeZoneCenter = LatLng(zone.centerLat, zone.centerLng);
        _radius = zone.radiusMeters;
        _locationSelected = true;
        _watchBehavior = zone.alarmEnabled && zone.vibrationEnabled
            ? 'both'
            : zone.alarmEnabled
                ? 'alarm'
                : 'vibrate';
      }
    }
  }

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('safe_zone_center'),
        position: _safeZoneCenter,
        infoWindow: const InfoWindow(title: 'Safe Zone Center'),
      ),
    };

    final liveLocation = ref.read(liveLocationProvider).valueOrNull;
    if (liveLocation != null &&
        liveLocation.latitude != null &&
        liveLocation.longitude != null) {
      markers.add(Marker(
        markerId: const MarkerId('patient_location'),
        position: LatLng(liveLocation.latitude!, liveLocation.longitude!),
        infoWindow: InfoWindow(
            title: ref.read(selectedPatientProvider)?.name ?? 'Patient'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return markers;
  }

  Future<void> _centerOnLocations() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[_safeZoneCenter];
    final liveLocation = ref.read(liveLocationProvider).valueOrNull;
    if (liveLocation?.latitude != null) {
      points.add(LatLng(liveLocation!.latitude!, liveLocation.longitude!));
    }

    try {
      if (points.length == 1) {
        await controller
            .animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      } else {
        final bounds = boundsFromPoints(points);
        await controller
            .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
      }
    } catch (_) {
      // Camera animation can fail if map is not fully ready; safe to ignore.
    }
  }

  Set<Circle> get _circles => {
        Circle(
          circleId: const CircleId('safe_zone_radius'),
          center: _safeZoneCenter,
          radius: _radius,
          strokeColor: AppColors.primaryColor,
          strokeWidth: 2,
          fillColor: AppColors.primaryColor.withAlpha(38),
        ),
      };

  Future<void> _saveSafeZone() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final patientId = ref.read(selectedPatientIdProvider);
    if (authUser == null || patientId == null) return;

    setState(() => _isSaving = true);

    try {
      final existingZone = ref.read(primarySafeZoneProvider);
      final zone = SafeZone(
        id: existingZone?.id ?? '',
        patientId: patientId,
        centerLat: _safeZoneCenter.latitude,
        centerLng: _safeZoneCenter.longitude,
        radiusMeters: _radius,
        isActive: true,
        alarmEnabled: _watchBehavior == 'alarm' || _watchBehavior == 'both',
        vibrationEnabled:
            _watchBehavior == 'vibrate' || _watchBehavior == 'both',
      );

      if (existingZone != null) {
        await ref
            .read(safeZoneRemoteSourceProvider)
            .saveSafeZone(authUser.uid, patientId, zone);
      } else {
        // New zone — let Firestore generate ID
        await ref
            .read(safeZoneRemoteSourceProvider)
            .saveSafeZone(authUser.uid, patientId, zone);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  Future<void> _deleteSafeZone() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    final patientId = ref.read(selectedPatientIdProvider);
    final existingZone = ref.read(primarySafeZoneProvider);
    if (authUser == null || patientId == null || existingZone == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Safe Zone?'),
        content: const Text(
            'This will remove the safe zone configuration. The watch will no longer monitor this boundary.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(safeZoneRemoteSourceProvider)
          .deleteSafeZone(authUser.uid, patientId, existingZone.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final szStatus = ref.watch(safeZoneStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Safe Zone Configuration',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_outline, color: AppColors.errorColor),
            onPressed: _deleteSafeZone,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Status Card
            _buildStatusCard(szStatus),

            // Offline Maps Warning
            if (!_offlineMapsConfirmed) _buildOfflineMapsWarning(),

            // Map
            Container(
              height: (sh * 0.45).clamp(300, 550),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withAlpha(66), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(38),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: GoogleMap(
                        initialCameraPosition: _initialCameraPosition,
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        onTap: (latLng) {
                          setState(() {
                            _safeZoneCenter = latLng;
                            _locationSelected = true;
                          });
                        },
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        markers: _markers,
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
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'safe_zone_config_center_fab',
                        backgroundColor: AppColors.surfaceColor,
                        onPressed: _centerOnLocations,
                        child: const Icon(
                          Icons.center_focus_strong,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Selected center card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withAlpha(128),
                  width: 2,
                ),
              ),
              child: _locationSelected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Center Location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_safeZoneCenter.latitude.toStringAsFixed(4)}, '
                          '${_safeZoneCenter.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Tap on the map to select safe zone center',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(height: 16),

            // Radius slider
            _buildRadiusSlider(),
            const SizedBox(height: 16),

            // Settings
            _buildSettingsSection(),
            const SizedBox(height: 16),

            // Events
            _buildEventLogs(),
            const SizedBox(height: 16),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: GradientButtonWithIcon(
                text: 'Save Safe Zone',
                icon: Icons.save,
                onPressed: _isSaving ? null : _saveSafeZone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SafeZoneStatus status) {
    final isInside = status == SafeZoneStatus.inside;
    final statusColor = isInside ? Colors.green : AppColors.errorColor;
    final statusIcon = isInside ? Icons.check_circle : Icons.warning;
    final statusText = switch (status) {
      SafeZoneStatus.inside => 'Inside Safe Zone',
      SafeZoneStatus.outside => 'Outside Safe Zone',
      SafeZoneStatus.unknown => 'Status Unknown',
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(128), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, size: 32, color: statusColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Status',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineMapsWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(66),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Offline Maps Not Configured',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Download offline maps for the safe zone area to ensure the watch can navigate even without internet.',
            style:
                TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await Navigator.pushNamed(context, Routes.offlineMaps);
              if (!mounted) return;
              setState(() => _offlineMapsConfirmed = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Setup Offline Maps'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withAlpha(153),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                'Safe Zone Radius',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Radius: ${_radius.round()} meters',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceColor,
            ),
          ),
          Slider(
            value: _radius,
            min: 20,
            max: 2000,
            divisions: 198,
            activeColor: AppColors.primaryColor,
            inactiveColor: AppColors.primaryColor.withAlpha(70),
            onChanged: (val) => setState(() => _radius = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                'Safety Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Watch Behavior on Exit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          RadioListTile<String>(
            value: 'vibrate',
            groupValue: _watchBehavior,
            activeColor: AppColors.primaryColor,
            title: const Text('Vibrate Only'),
            subtitle: Text('Watch vibrates when leaving zone',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            onChanged: (val) {
              if (val != null) setState(() => _watchBehavior = val);
            },
          ),
          RadioListTile<String>(
            value: 'alarm',
            groupValue: _watchBehavior,
            activeColor: AppColors.primaryColor,
            title: const Text('Sound Alarm'),
            subtitle: Text('Watch plays alarm sound',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            onChanged: (val) {
              if (val != null) setState(() => _watchBehavior = val);
            },
          ),
          RadioListTile<String>(
            value: 'both',
            groupValue: _watchBehavior,
            activeColor: AppColors.primaryColor,
            title: const Text('Vibrate + Alarm'),
            subtitle: Text('Both vibration and alarm',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            onChanged: (val) {
              if (val != null) setState(() => _watchBehavior = val);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Alert on Exit'),
            value: _alertOnExit,
            activeTrackColor: AppColors.primaryColor,
            onChanged: (val) => setState(() => _alertOnExit = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLogs() {
    final eventsAsync = ref.watch(safeZoneEventsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: AppColors.primaryColor),
              SizedBox(width: 8),
              Text(
                'Recent Events',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          eventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Text(
                  'No safe zone events recorded',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                );
              }
              return Column(
                children: events.take(5).map((event) {
                  final timeStr =
                      DateFormat('MMM d, h:mm a').format(event.timestamp);
                  final isExit = event.eventType.name == 'exit';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isExit
                            ? AppColors.errorColor.withAlpha(77)
                            : Colors.green.withAlpha(77),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isExit ? Icons.warning : Icons.check_circle,
                          color: isExit
                              ? AppColors.errorColor
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExit ? 'Zone Exit' : 'Zone Enter',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'Unable to load events',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
