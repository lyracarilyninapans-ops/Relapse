import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/memory_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/utils/map_marker_icon_utils.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory map screen with search toggle, real memory markers, and FAB.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  bool _pendingInitialFocus = true;
  Set<Marker> _cachedMarkers = <Marker>{};
  Set<Circle> _cachedCircles = <Circle>{};
  String _markerSignature = '';
  String _circleSignature = '';
  BitmapDescriptor _patientMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor _memoryMarkerIcon =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 13.2,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadMarkerIcons());
  }

  Future<void> _loadMarkerIcons() async {
    final patientIcon = await MapMarkerIconUtils.materialIconMarker(
      icon: Icons.person_pin_circle,
      iconColor: AppColors.gradientStart,
    );
    final memoryIcon = await MapMarkerIconUtils.materialIconMarker(
      icon: Icons.place,
      iconColor: AppColors.gradientMiddle,
    );

    if (!mounted) return;
    setState(() {
      _patientMarkerIcon = patientIcon;
      _memoryMarkerIcon = memoryIcon;
      _markerSignature = '';
      _cachedMarkers = <Marker>{};
    });
  }

  Set<Marker> _buildMarkersMemoized(
    List<MemoryReminder> reminders,
    LatLng? patientPos,
  ) {
    final patientName = ref.read(selectedPatientProvider)?.name ?? 'Patient';
    final markerKey = [
      'patient:${patientPos?.latitude}:${patientPos?.longitude}:$patientName',
      for (final reminder in reminders)
        'r:${reminder.id}:${reminder.latitude}:${reminder.longitude}:${reminder.title}',
    ].join('|');
    if (markerKey == _markerSignature) {
      return _cachedMarkers;
    }

    final markers = <Marker>{};

    for (final reminder in reminders) {
      if (reminder.latitude != null && reminder.longitude != null) {
        markers.add(Marker(
          markerId: MarkerId('memory_${reminder.id}'),
          position: LatLng(reminder.latitude!, reminder.longitude!),
          infoWindow: InfoWindow(title: reminder.title),
          icon: _memoryMarkerIcon,
        ));
      }
    }

    if (patientPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('patient_location'),
        position: patientPos,
        infoWindow: InfoWindow(title: patientName),
        icon: _patientMarkerIcon,
      ));
    }

    _markerSignature = markerKey;
    _cachedMarkers = markers;
    return markers;
  }

  Set<Circle> _buildCirclesMemoized(List<MemoryReminder> reminders) {
    final circleKey = reminders
        .map((r) => '${r.id}:${r.latitude}:${r.longitude}:${r.radiusMeters}')
        .join('|');
    if (circleKey == _circleSignature) {
      return _cachedCircles;
    }

    final circles = reminders
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) => Circle(
              circleId: CircleId('memory_radius_${r.id}'),
              center: LatLng(r.latitude!, r.longitude!),
              radius: r.radiusMeters,
              strokeColor: AppColors.primaryColor.withAlpha(128),
              strokeWidth: 1,
              fillColor: AppColors.primaryColor.withAlpha(26),
            ))
        .toSet();

    _circleSignature = circleKey;
    _cachedCircles = circles;
    return circles;
  }

  Future<void> _focusReminder(MemoryReminder reminder) async {
    if (_mapController == null ||
        reminder.latitude == null ||
        reminder.longitude == null) {
      return;
    }
    await _mapController!.animateCamera(
      CameraUpdate.newLatLng(LatLng(reminder.latitude!, reminder.longitude!)),
    );
  }

  /// Latest patient position from live location stream.
  LatLng? _computePatientPosition() {
    final liveRecord = ref.read(liveLocationProvider).valueOrNull;
    if (liveRecord != null &&
        liveRecord.latitude != null &&
        liveRecord.longitude != null) {
      return LatLng(liveRecord.latitude!, liveRecord.longitude!);
    }
    return null;
  }

  /// Attempts to auto-focus the map on the best available position.
  /// Called from onMapCreated and post-frame callbacks until successful.
  void _tryAutoFocus() {
    if (!_pendingInitialFocus || _mapController == null) {
      return;
    }
    final pos = _computePatientPosition();
    debugPrint('[MemoryScreen] _tryAutoFocus: pos=$pos');
    if (pos != null) {
      _pendingInitialFocus = false;
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
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
            'Memories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: const NoPatientLinkedView(featureLabel: 'memory cues'),
      );
    }

    final reminders = ref.watch(activeMemoryRemindersProvider);
    final liveLocation = ref.watch(liveLocationProvider);
    final hasMemories = reminders.isNotEmpty;

    final patientPos = liveLocation.whenOrNull(
      data: (record) => record != null &&
          record.latitude != null &&
          record.longitude != null
          ? LatLng(record.latitude!, record.longitude!)
          : null,
    );

    // Auto-focus: schedule after each build until successful
    if (_pendingInitialFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoFocus());
    }

    final query = _searchController.text.toLowerCase();
    final filteredReminders = query.isEmpty
        ? reminders
        : reminders
            .where((r) => r.title.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search memories...',
                  hintStyle: TextStyle(color: Colors.black54),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const GradientText(
                'Memories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _mapController = controller;
              _tryAutoFocus();
            },
            markers: _buildMarkersMemoized(reminders, patientPos),
            circles: _buildCirclesMemoized(reminders),
            compassEnabled: true,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Empty state overlay
          if (!hasMemories)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No memories added yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add your first memory',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Search results overlay
          if (_isSearching && query.isNotEmpty)
            Positioned(
              top: 0,
              left: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: filteredReminders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No matches found'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: filteredReminders.length.clamp(0, 5),
                        separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                        itemBuilder: (context, i) => ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Colors.blue),
                          title: Text(filteredReminders[i].title),
                          onTap: () {
                            setState(() => _isSearching = false);
                            _focusReminder(filteredReminders[i]);
                          },
                        ),
                      ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'memory_center_fab',
            backgroundColor: AppColors.surfaceColor,
            onPressed: () {
              final pos = _computePatientPosition();
              if (pos != null) {
                _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(pos, 15));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('No location data available yet')),
                );
              }
            },
            child: const Icon(
              Icons.center_focus_strong,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: FloatingActionButton(
              heroTag: 'memory_add_fab',
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () {
                Navigator.pushNamed(context, Routes.createMemory);
              },
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
