import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/screens/activity/widgets/activity_map_widgets.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/utils/map_marker_icon_utils.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

class ActivityCurrentLocationCard extends ConsumerStatefulWidget {
  final double screenWidth;

  const ActivityCurrentLocationCard({
    super.key,
    required this.screenWidth,
  });

  @override
  ConsumerState<ActivityCurrentLocationCard> createState() =>
      _ActivityCurrentLocationCardState();
}

class _ActivityCurrentLocationCardState
    extends ConsumerState<ActivityCurrentLocationCard> {
  GoogleMapController? _mapController;
  LatLng? _lastCameraTarget;
  bool _autoFollow = true;
  bool _isAnimatingCamera = false;
  Set<Marker> _cachedMapMarkers = <Marker>{};
  Set<Polyline> _cachedMapPolylines = <Polyline>{};
  Set<Circle> _cachedSafeZoneCircles = <Circle>{};
  String _markerSignature = '';
  String _polylineSignature = '';
  String _circleSignature = '';
  BitmapDescriptor _currentLocationMarkerIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMarkerIcons());
  }

  Future<void> _loadMarkerIcons() async {
    final currentLocationIcon = await MapMarkerIconUtils.materialIconMarker(
      icon: Icons.person_pin_circle,
      iconColor: AppColors.gradientStart,
    );

    if (!mounted) return;
    setState(() {
      _currentLocationMarkerIcon = currentLocationIcon;
      _markerSignature = '';
      _cachedMapMarkers = <Marker>{};
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _maybeAnimateCamera(LatLng target) {
    if (!_autoFollow) return;

    final controller = _mapController;
    if (controller == null) return;

    final last = _lastCameraTarget;
    if (last != null) {
      final movedMeters = _haversineDistance(
        last.latitude,
        last.longitude,
        target.latitude,
        target.longitude,
      );
      if (movedMeters < 15) return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _mapController == null) return;
      _isAnimatingCamera = true;
      _mapController!.animateCamera(CameraUpdate.newLatLng(target));
      _lastCameraTarget = target;
    });
  }

  void _resumeAutoFollow(LatLng target) {
    setState(() {
      _autoFollow = true;
    });
    _isAnimatingCamera = true;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16),
      ),
    );
    _lastCameraTarget = target;
  }

  Set<Marker> _buildMarkersMemoized(LatLng? currentLatLng) {
    final signature =
        'current:${currentLatLng?.latitude}:${currentLatLng?.longitude}';
    if (signature == _markerSignature) {
      return _cachedMapMarkers;
    }

    final markers = <Marker>{
      if (currentLatLng != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLatLng,
          icon: _currentLocationMarkerIcon,
        ),
    };

    _markerSignature = signature;
    _cachedMapMarkers = markers;
    return markers;
  }

  Set<Polyline> _buildPolylinesMemoized(List<ActivityRecord> historyRecords) {
    final signature =
        historyRecords.map((r) => '${r.id}:${r.latitude}:${r.longitude}').join('|');
    if (signature == _polylineSignature) {
      return _cachedMapPolylines;
    }

    final historicalPoints = historyRecords
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) => LatLng(r.latitude!, r.longitude!))
        .toList();

    final polylines = <Polyline>{
      if (historicalPoints.length > 1)
        Polyline(
          polylineId: const PolylineId('history_path'),
          points: historicalPoints.reversed.toList(),
          color: AppColors.gradientStart,
          width: 4,
          jointType: JointType.round,
        ),
    };

    _polylineSignature = signature;
    _cachedMapPolylines = polylines;
    return polylines;
  }

  Set<Circle> _buildSafeZoneCirclesMemoized(List<SafeZone> safeZones) {
    final signature = safeZones
        .map((z) => '${z.id}:${z.centerLat}:${z.centerLng}:${z.radiusMeters}')
        .join('|');
    if (signature == _circleSignature) {
      return _cachedSafeZoneCircles;
    }

    final circles = <Circle>{
      for (final zone in safeZones)
        Circle(
          circleId: CircleId('safe_zone_${zone.id}'),
          center: LatLng(zone.centerLat, zone.centerLng),
          radius: zone.radiusMeters,
          strokeWidth: 2,
          strokeColor: AppColors.safeZoneInsideStart.withAlpha(180),
          fillColor: AppColors.safeZoneInsideStart.withAlpha(40),
        ),
    };

    _circleSignature = signature;
    _cachedSafeZoneCircles = circles;
    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final liveLocation = ref.watch(liveLocationProvider);
    final szStatus = ref.watch(safeZoneStatusProvider);
    final safeZones = ref.watch(safeZoneConfigProvider).valueOrNull ?? const [];

    final currentRecord = liveLocation.valueOrNull;
    final hasLiveCoords =
        currentRecord?.latitude != null && currentRecord?.longitude != null;
    final currentLatLng = hasLiveCoords
        ? LatLng(currentRecord!.latitude!, currentRecord.longitude!)
        : null;

    if (currentLatLng != null) {
      _maybeAnimateCamera(currentLatLng);
    }

    final mapMarkers = _buildMarkersMemoized(currentLatLng);

    final historyAsync = ref.watch(locationHistoryProvider);
    final historyRecords = historyAsync.valueOrNull ?? const <ActivityRecord>[];
    final mapPolylines = _buildPolylinesMemoized(historyRecords);
    final safeZoneCircles = _buildSafeZoneCirclesMemoized(safeZones);

    final locationContent = liveLocation.when(
      data: (record) {
        if (record == null) {
          return Text(
            'Waiting for location...',
            style: TextStyle(
              fontSize: scaledFontSize(15, widget.screenWidth),
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          );
        }

        final lat = record.latitude;
        final lng = record.longitude;
        if (lat == null || lng == null) {
          return Text(
            'Location unavailable',
            style: TextStyle(
              fontSize: scaledFontSize(15, widget.screenWidth),
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          );
        }

        return ActivityResolvedLocationText(
          latitude: lat,
          longitude: lng,
          fallback: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          resolvingText: 'Resolving location...',
          style: TextStyle(
            fontSize: scaledFontSize(15, widget.screenWidth),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        );
      },
      loading: () => Text(
        'Loading location...',
        style: TextStyle(
          fontSize: scaledFontSize(15, widget.screenWidth),
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
      error: (error, stackTrace) => Text(
        'Location unavailable',
        style: TextStyle(
          fontSize: scaledFontSize(15, widget.screenWidth),
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );

    final updatedText = liveLocation.when(
      data: (record) {
        if (record == null) return '';
        final diff = DateTime.now().difference(record.timestamp);
        if (diff.inMinutes < 1) return 'Updated just now';
        if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} min ago';
        return 'Updated ${diff.inHours}h ago';
      },
      loading: () => '',
      error: (error, stackTrace) => '',
    );

    final isInside = szStatus == SafeZoneStatus.inside;
    final szLabel = switch (szStatus) {
      SafeZoneStatus.inside => 'Safe Zone',
      SafeZoneStatus.outside => 'Outside',
      SafeZoneStatus.unknown => 'Unknown',
    };

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardBorder,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(13.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(13.5)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13.5)),
                child: Stack(
                  children: [
                    if (currentLatLng != null)
                      RepaintBoundary(
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: currentLatLng,
                            zoom: 16,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                            _lastCameraTarget = currentLatLng;
                          },
                          onCameraMoveStarted: () {
                            if (_isAnimatingCamera) return;
                            if (_autoFollow && mounted) {
                              setState(() {
                                _autoFollow = false;
                              });
                            }
                          },
                          onCameraIdle: () {
                            _isAnimatingCamera = false;
                          },
                          markers: mapMarkers,
                          circles: safeZoneCircles,
                          polylines: mapPolylines,
                          mapToolbarEnabled: false,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: false,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.gradientStart.withAlpha(40),
                              AppColors.gradientMiddle.withAlpha(40),
                              AppColors.gradientEnd.withAlpha(40),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            ..._buildGridLines(),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.button,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gradientStart.withAlpha(100),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.gradientMiddle.withAlpha(80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.safeZoneInsideStart,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.safeZoneInsideStart.withAlpha(100),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (currentLatLng != null && !_autoFollow)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _resumeAutoFollow(currentLatLng),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceColor.withAlpha(230),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.gradientStart.withAlpha(120),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    size: 14,
                                    color: AppColors.gradientStart,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Recenter',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gradientStart,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (currentLatLng != null)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActivityFullScreenMapPage(
                                    initialTarget: currentLatLng,
                                    markers: mapMarkers,
                                    polylines: mapPolylines,
                                    circles: safeZoneCircles,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceColor.withAlpha(230),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Icon(
                                Icons.fullscreen,
                                size: 20,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gradientStart.withAlpha(30),
                          AppColors.gradientMiddle.withAlpha(30),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const GradientIcon(Icons.location_on, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        locationContent,
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              updatedText,
                              style: TextStyle(
                                fontSize: scaledFontSize(12, widget.screenWidth),
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isInside
                                        ? AppColors.safeZoneInsideStart
                                        : AppColors.safeZoneOutsideStart)
                                    .withAlpha(26),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                szLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isInside
                                      ? AppColors.safeZoneInsideStart
                                      : AppColors.safeZoneOutsideStart,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGridLines() {
    return [
      for (int i = 1; i < 4; i++)
        Positioned(
          top: i * 40.0,
          left: 0,
          right: 0,
          child: Container(
              height: 0.5, color: AppColors.gradientMiddle.withAlpha(30)),
        ),
      for (int i = 1; i < 6; i++)
        Positioned(
          left: i * 70.0,
          top: 0,
          bottom: 0,
          child: Container(
              width: 0.5, color: AppColors.gradientMiddle.withAlpha(30)),
        ),
    ];
  }

  static double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
