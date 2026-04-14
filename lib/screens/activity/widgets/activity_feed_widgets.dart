import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/screens/activity/widgets/activity_map_widgets.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';

class ActivityRecentActivityFeed extends ConsumerWidget {
  final double screenWidth;

  const ActivityRecentActivityFeed({super.key, required this.screenWidth});

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
                  child: Icon(eventInfo.icon, size: 20, color: eventInfo.color),
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
                        record.metadata?['description'] as String? ?? eventInfo.subtitle,
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
          if (!isLast) Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
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

class ActivityLocationHistoryTimeline extends ConsumerStatefulWidget {
  final double screenWidth;

  const ActivityLocationHistoryTimeline({super.key, required this.screenWidth});

  @override
  ConsumerState<ActivityLocationHistoryTimeline> createState() =>
      _ActivityLocationHistoryTimelineState();
}

class _ActivityLocationHistoryTimelineState
    extends ConsumerState<ActivityLocationHistoryTimeline> {
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
        final visibleCount = _showAll ? totalCount : totalCount.clamp(0, _initialLimit);

        return Column(
          children: [
            ...List.generate(
              visibleCount,
              (i) {
                final record = displayedRecords[displayedRecords.length - 1 - i];
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
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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

  static double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
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

  Widget _buildLocationTile(ActivityRecord record, bool isLast, bool isCurrent) {
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
                if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
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
                      color: isCurrent ? AppColors.gradientStart : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (record.latitude != null && record.longitude != null)
                          ActivityResolvedLocationText(
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
