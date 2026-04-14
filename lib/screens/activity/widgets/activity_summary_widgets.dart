import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';

class ActivityDateFilterRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ActivityDateFilterRow({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

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

class ActivityDailySummaryRow extends ConsumerWidget {
  final double screenWidth;

  const ActivityDailySummaryRow({super.key, required this.screenWidth});

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

class ActivityMovementChartCard extends ConsumerWidget {
  final double screenWidth;

  const ActivityMovementChartCard({super.key, required this.screenWidth});

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
            child: RepaintBoundary(
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
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('6 AM', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('12 PM', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('6 PM', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              Text('12 AM', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}
