import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/utils/date_range.dart';
import 'package:relapse_flutter/utils/geocoding_utils.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Activity monitoring screen with location overview, daily summary,
/// recent activity feed, and location history.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final patient = ref.watch(selectedPatientProvider);

    if (patient == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          title: const GradientText(
            'Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: const NoPatientLinkedView(featureLabel: 'activity monitoring'),
      );
    }

    final filter = ref.watch(selectedDateRangeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const GradientIcon(Icons.calendar_today_outlined, size: 22),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: now,
                initialDateRange: DateTimeRange(
                  start: now.subtract(const Duration(days: 7)),
                  end: now,
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.primaryColor,
                          ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(customDateRangeProvider.notifier).state = 
                    DateRange.custom(picked.start, picked.end);
                ref.read(selectedDateRangeFilterProvider.notifier).state =
                    DateRangeFilter.custom;
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date filter chips ──
            _DateFilterRow(
              selectedIndex: filter.index,
              onSelected: (i) {
                ref.read(selectedDateRangeFilterProvider.notifier).state =
                    DateRangeFilter.values[i];
              },
            ),
            const SizedBox(height: 20),

            // ── Current Location Card ──
            _CurrentLocationCard(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Daily Summary ──
            SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'DAILY SUMMARY',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            _DailySummaryRow(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Activity Chart ──
            SectionHeader(
              icon: Icons.show_chart_outlined,
              title: 'MOVEMENT PATTERN',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            _MovementChartCard(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Recent Activity Feed ──
            SectionHeader(
              icon: Icons.notifications_outlined,
              title: 'RECENT ACTIVITY',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            _RecentActivityFeed(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Location History ──
            SectionHeader(
              icon: Icons.location_on_outlined,
              title: 'LOCATION HISTORY',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            _LocationHistoryTimeline(screenWidth: sw),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Date Filter Row ──────────────────────────────────────────────────
class _DateFilterRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DateFilterRow({required this.selectedIndex, required this.onSelected});

  static const _labels = ['Today', 'This Week', 'This Month', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (i) {
        final isSelected = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 6,
              right: i == _labels.length - 1 ? 0 : 6,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppGradients.button : null,
                    color: isSelected ? null : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.grey.shade300),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.gradientMiddle.withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Current Location Card ────────────────────────────────────────────
class _CurrentLocationCard extends ConsumerStatefulWidget {
  final double screenWidth;
  const _CurrentLocationCard({required this.screenWidth});

  @override
  ConsumerState<_CurrentLocationCard> createState() =>
      _CurrentLocationCardState();
}

class _CurrentLocationCardState extends ConsumerState<_CurrentLocationCard> {
  GoogleMapController? _mapController;
  LatLng? _lastCameraTarget;
  bool _autoFollow = true;
  bool _isAnimatingCamera = false;

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

    final mapMarkers = <Marker>{
      if (currentLatLng != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: currentLatLng,
        ),
    };

    final historyAsync = ref.watch(locationHistoryProvider);
    final historicalPoints = historyAsync.maybeWhen(
      data: (records) => records
          .where((r) => r.latitude != null && r.longitude != null)
          .map((r) => LatLng(r.latitude!, r.longitude!))
          .toList(),
      orElse: () => <LatLng>[],
    );

    final mapPolylines = <Polyline>{
      if (historicalPoints.length > 1)
        Polyline(
          polylineId: const PolylineId('history_path'),
          points: historicalPoints.reversed.toList(), // oldest to newest
          color: AppColors.gradientStart,
          width: 4,
          jointType: JointType.round,
        ),
    };

    final safeZoneCircles = <Circle>{
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

        return _ResolvedLocationText(
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
            // Live map (fallback placeholder when no coordinates yet)
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13.5),
                ),
                child: Stack(
                  children: [
                    if (currentLatLng != null)
                      GoogleMap(
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
                                          color: AppColors.gradientStart
                                              .withAlpha(100),
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
                                      color: AppColors.gradientMiddle
                                          .withAlpha(80),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // "Live" badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.safeZoneInsideStart,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.safeZoneInsideStart
                                  .withAlpha(100),
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
                    // Fullscreen button
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
                                  builder: (_) => _FullScreenMapPage(
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
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
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
            // Location info
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
                                fontSize: scaledFontSize(
                                    12, widget.screenWidth),
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

// ─── Daily Summary Row ────────────────────────────────────────────────
class _DailySummaryRow extends ConsumerWidget {
  final double screenWidth;
  const _DailySummaryRow({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider);
    final todayFeed = ref.watch(todayActivityFeedProvider);

    final fallbackDistanceMeters = todayFeed.when(
      data: _calculateFallbackDistanceMeters,
      loading: () => 0.0,
      error: (error, stackTrace) => 0.0,
    );

    final fallbackPlacesVisited = todayFeed.when(
      data: _calculateFallbackPlacesVisited,
      loading: () => 0,
      error: (error, stackTrace) => 0,
    );

    final distance = summary.when(
      data: (s) {
        final meters = s?.distanceMeters ?? fallbackDistanceMeters;
        if (meters <= 0) return '--';
        if (meters >= 1000) {
          return '${(meters / 1000).toStringAsFixed(1)} km';
        }
        return '${meters.toInt()} m';
      },
      loading: () => '...',
      error: (error, stackTrace) => '--',
    );

    final timeOutside = summary.when(
      data: (s) {
        if (s == null) return '--';
        final hours = s.activeMinutes ~/ 60;
        final mins = s.activeMinutes % 60;
        if (hours > 0) return '${hours}h ${mins}m';
        return '${mins}m';
      },
      loading: () => '...',
      error: (error, stackTrace) => '--',
    );

    final places = summary.when(
      data: (s) {
        final places = s?.placesVisited ?? fallbackPlacesVisited;
        return places > 0 ? places.toString() : '--';
      },
      loading: () => '...',
      error: (error, stackTrace) => '--',
    );

    return Row(
      children: [
        _SummaryCard(
          icon: Icons.directions_walk,
          value: distance,
          label: 'Distance',
          color: AppColors.gradientStart,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          icon: Icons.timer_outlined,
          value: timeOutside,
          label: 'Time Outside',
          color: AppColors.gradientMiddle,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          icon: Icons.place_outlined,
          value: places,
          label: 'Places',
          color: AppColors.gradientEnd,
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  static double _calculateFallbackDistanceMeters(List<ActivityRecord> records) {
    final points = records
        .where((r) =>
            r.eventType == ActivityEventType.locationUpdate &&
            r.latitude != null &&
            r.longitude != null)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (points.length < 2) return 0.0;

    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += _haversineDistance(
        points[i - 1].latitude!,
        points[i - 1].longitude!,
        points[i].latitude!,
        points[i].longitude!,
      );
    }
    return total;
  }

  static int _calculateFallbackPlacesVisited(List<ActivityRecord> records) {
    final cells = <String>{};
    for (final record in records) {
      if (record.eventType != ActivityEventType.locationUpdate ||
          record.latitude == null ||
          record.longitude == null) {
        continue;
      }
      final latCell = (record.latitude! * 1000).floor();
      final lngCell = (record.longitude! * 1000).floor();
      cells.add('$latCell:$lngCell');
    }
    return cells.length;
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

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double screenWidth;

  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: scaledFontSize(18, screenWidth),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: scaledFontSize(11, screenWidth),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Movement Chart Card ──────────────────────────────────────────────
class _MovementChartCard extends ConsumerWidget {
  final double screenWidth;
  const _MovementChartCard({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourlyAsync = ref.watch(hourlyActivityProvider);

    final hourlyData = hourlyAsync.when(
      data: (counts) {
        final maxVal = counts.reduce((a, b) => a > b ? a : b);
        if (maxVal == 0) return List<double>.filled(24, 0.0);
        return counts.map((c) => c / maxVal).toList();
      },
      loading: () => List<double>.filled(24, 0.0),
      error: (error, stackTrace) => List<double>.filled(24, 0.0),
    );

    // Find peak hour
    final rawCounts = hourlyAsync.valueOrNull ?? List<int>.filled(24, 0);
    int peakHour = 0;
    int peakVal = 0;
    for (int i = 0; i < rawCounts.length; i++) {
      if (rawCounts[i] > peakVal) {
        peakVal = rawCounts[i];
        peakHour = i;
      }
    }
    final peakLabel = peakVal > 0
        ? 'Peak: ${peakHour == 0 ? 12 : (peakHour > 12 ? peakHour - 12 : peakHour)} ${peakHour < 12 ? 'AM' : 'PM'}'
        : 'No activity';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: scaledFontSize(12, screenWidth),
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                peakLabel,
                style: TextStyle(
                  fontSize: scaledFontSize(12, screenWidth),
                  fontWeight: FontWeight.w600,
                  color: AppColors.gradientStart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final v = hourlyData[i];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: v.clamp(0.05, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.gradientStart.withAlpha(
                                      (255 * (0.4 + v * 0.6)).toInt(),
                                    ),
                                    AppColors.gradientMiddle.withAlpha(
                                      (255 * (0.4 + v * 0.6)).toInt(),
                                    ),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('6 AM',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('12 PM',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('6 PM',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('12 AM',
                  style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity Feed ─────────────────────────────────────────────
class _RecentActivityFeed extends ConsumerWidget {
  final double screenWidth;
  const _RecentActivityFeed({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(activityFeedProvider);

    return feedAsync.when(
      data: (records) {
        final notableEvents = records
            .where((record) => record.eventType != ActivityEventType.locationUpdate)
            .toList();

        if (notableEvents.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No notable activity yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              notableEvents.length > 10 ? 10 : notableEvents.length,
              (i) {
                final record = notableEvents[i];
                final isLast =
                    i == (notableEvents.length > 10 ? 9 : notableEvents.length - 1);
                return _buildEventTile(record, isLast);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Unable to load activity',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(ActivityRecord record, bool isLast) {
    final eventInfo = _eventDisplayInfo(record.eventType);
    final timeStr = DateFormat('h:mm a').format(record.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: eventInfo.color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(eventInfo.icon, size: 20, color: eventInfo.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventInfo.title,
                        style: TextStyle(
                          fontSize: scaledFontSize(14, screenWidth),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.metadata?['description'] as String? ??
                            eventInfo.subtitle,
                        style: TextStyle(
                          fontSize: scaledFontSize(12, screenWidth),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: scaledFontSize(11, screenWidth),
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  _EventDisplayInfo _eventDisplayInfo(ActivityEventType type) {
    switch (type) {
      case ActivityEventType.safeZoneEnter:
        return _EventDisplayInfo(
          icon: Icons.shield_outlined,
          title: 'Entered Safe Zone',
          subtitle: 'Returned to safe area',
          color: AppColors.safeZoneInsideStart,
        );
      case ActivityEventType.safeZoneExit:
        return _EventDisplayInfo(
          icon: Icons.warning_amber_outlined,
          title: 'Left Safe Zone',
          subtitle: 'Exited safe area boundary',
          color: AppColors.safeZoneOutsideStart,
        );
      case ActivityEventType.reminderTriggered:
        return _EventDisplayInfo(
          icon: Icons.notifications_active_outlined,
          title: 'Memory Reminder Triggered',
          subtitle: 'Geo-reminder activated',
          color: AppColors.gradientStart,
        );
      case ActivityEventType.watchDisconnected:
        return _EventDisplayInfo(
          icon: Icons.watch_off,
          title: 'Watch Disconnected',
          subtitle: 'Device went offline',
          color: AppColors.watchDisconnected,
        );
      case ActivityEventType.watchReconnected:
        return _EventDisplayInfo(
          icon: Icons.watch,
          title: 'Watch Reconnected',
          subtitle: 'Device is back online',
          color: AppColors.watchConnected,
        );
      case ActivityEventType.locationUpdate:
        return _EventDisplayInfo(
          icon: Icons.directions_walk,
          title: 'Location Update',
          subtitle: 'Movement detected',
          color: AppColors.tertiaryColor,
        );
    }
  }
}

class _EventDisplayInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EventDisplayInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ─── Location History Timeline ────────────────────────────────────────
class _LocationHistoryTimeline extends ConsumerStatefulWidget {
  final double screenWidth;
  const _LocationHistoryTimeline({required this.screenWidth});

  @override
  ConsumerState<_LocationHistoryTimeline> createState() =>
      _LocationHistoryTimelineState();
}

class _LocationHistoryTimelineState
    extends ConsumerState<_LocationHistoryTimeline> {
  static const _initialLimit = 15;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(locationHistoryProvider);

    return historyAsync.when(
      data: (records) {
        final displayedRecords = _downsampleHistory(records);

        if (displayedRecords.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No location history available',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          );
        }

        final totalCount = displayedRecords.length;
        final visibleCount =
            _showAll ? totalCount : totalCount.clamp(0, _initialLimit);

        return Column(
          children: [
            ...List.generate(
              visibleCount,
              (i) {
                final record =
                    displayedRecords[displayedRecords.length - 1 - i];
                final isLast = i == visibleCount - 1;
                final isCurrent = i == 0;
                return _buildLocationTile(record, isLast, isCurrent);
              },
            ),
            if (!_showAll && totalCount > _initialLimit) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showAll = true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Show All (${totalCount - _initialLimit} more)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Unable to load history',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ),
    );
  }

  static List<ActivityRecord> _downsampleHistory(List<ActivityRecord> records) {
    if (records.isEmpty) return records;

    final sorted = [...records]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sampled = <ActivityRecord>[];

    ActivityRecord? lastKept;
    for (final record in sorted) {
      if (lastKept == null) {
        sampled.add(record);
        lastKept = record;
        continue;
      }

      if (record.latitude == null ||
          record.longitude == null ||
          lastKept.latitude == null ||
          lastKept.longitude == null) {
        sampled.add(record);
        lastKept = record;
        continue;
      }

      final distanceMeters = _haversineDistance(
        lastKept.latitude!,
        lastKept.longitude!,
        record.latitude!,
        record.longitude!,
      );
      final minutesGap = record.timestamp.difference(lastKept.timestamp).inMinutes;

      if (distanceMeters >= 100 || minutesGap >= 5) {
        sampled.add(record);
        lastKept = record;
      }
    }

    if (sampled.isNotEmpty && sampled.last.id != sorted.last.id) {
      sampled.add(sorted.last);
    }

    return sampled;
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

  Widget _buildLocationTile(
      ActivityRecord record, bool isLast, bool isCurrent) {
    final timeStr = DateFormat('h:mm a').format(record.timestamp);
    final coords =
      '${record.latitude?.toStringAsFixed(4)}, ${record.longitude?.toStringAsFixed(4)}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCurrent ? AppGradients.button : null,
                    color: isCurrent ? null : Colors.grey.shade300,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.gradientStart.withAlpha(80),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                    ? Border.all(
                        color: AppColors.gradientStart.withAlpha(60),
                        width: 1.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
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
                      color: isCurrent
                          ? AppColors.gradientStart.withAlpha(26)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 22,
                      color: isCurrent
                          ? AppColors.gradientStart
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (record.latitude != null && record.longitude != null)
                          _ResolvedLocationText(
                            latitude: record.latitude!,
                            longitude: record.longitude!,
                            fallback: coords,
                            resolvingText: 'Resolving location...',
                            style: TextStyle(
                              fontSize: scaledFontSize(14, widget.screenWidth),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          )
                        else
                          Text(
                            'Location unavailable',
                            style: TextStyle(
                              fontSize: scaledFontSize(14, widget.screenWidth),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: scaledFontSize(10, widget.screenWidth),
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedLocationText extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String fallback;
  final String resolvingText;
  final TextStyle style;

  const _ResolvedLocationText({
    required this.latitude,
    required this.longitude,
    required this.fallback,
    this.resolvingText = 'Resolving location...',
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: GeocodingUtils.reverseGeocodeCoordinates(latitude, longitude),
      builder: (context, snapshot) {
        final label = snapshot.data;
        final displayText = snapshot.connectionState == ConnectionState.waiting
            ? resolvingText
            : (label != null && label.isNotEmpty)
                ? label
                : fallback;
        return Text(
          displayText,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

// ─── Full Screen Map Page ─────────────────────────────────────────────
class _FullScreenMapPage extends StatelessWidget {
  final LatLng initialTarget;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;

  const _FullScreenMapPage({
    required this.initialTarget,
    required this.markers,
    required this.polylines,
    required this.circles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 16,
            ),
            markers: markers,
            polylines: polylines,
            circles: circles,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor.withAlpha(230),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 22,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
