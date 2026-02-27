import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Activity monitoring screen with location overview, daily summary,
/// recent activity feed, and location history.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
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
            onPressed: () {},
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

  static const _labels = ['Today', 'This Week', 'This Month'];

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
class _CurrentLocationCard extends ConsumerWidget {
  final double screenWidth;
  const _CurrentLocationCard({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveLocation = ref.watch(liveLocationProvider);
    final szStatus = ref.watch(safeZoneStatusProvider);

    final locationText = liveLocation.when(
      data: (record) {
        if (record == null) return 'Waiting for location...';
        return '${record.latitude?.toStringAsFixed(5)}, ${record.longitude?.toStringAsFixed(5)}';
      },
      loading: () => 'Loading location...',
      error: (_, __) => 'Location unavailable',
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
      error: (_, __) => '',
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
            // Map placeholder
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13.5),
                ),
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
                            color:
                                AppColors.safeZoneInsideStart.withAlpha(100),
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
                ],
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
                        Text(
                          locationText,
                          style: TextStyle(
                            fontSize: scaledFontSize(15, screenWidth),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              updatedText,
                              style: TextStyle(
                                fontSize: scaledFontSize(12, screenWidth),
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
}

// ─── Daily Summary Row ────────────────────────────────────────────────
class _DailySummaryRow extends ConsumerWidget {
  final double screenWidth;
  const _DailySummaryRow({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider);

    final distance = summary.when(
      data: (s) {
        if (s == null) return '--';
        if (s.distanceMeters >= 1000) {
          return '${(s.distanceMeters / 1000).toStringAsFixed(1)} km';
        }
        return '${s.distanceMeters.toInt()} m';
      },
      loading: () => '...',
      error: (_, __) => '--',
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
      error: (_, __) => '--',
    );

    final places = summary.when(
      data: (s) => s?.placesVisited.toString() ?? '--',
      loading: () => '...',
      error: (_, __) => '--',
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
      error: (_, __) => List<double>.filled(24, 0.0),
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
        if (records.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No activity recorded yet',
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
              records.length > 10 ? 10 : records.length,
              (i) {
                final record = records[i];
                final isLast =
                    i == (records.length > 10 ? 9 : records.length - 1);
                return _buildEventTile(record, isLast);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Container(
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
class _LocationHistoryTimeline extends ConsumerWidget {
  final double screenWidth;
  const _LocationHistoryTimeline({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(locationHistoryProvider);

    return historyAsync.when(
      data: (records) {
        if (records.isEmpty) {
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

        return Column(
          children: List.generate(
            records.length > 10 ? 10 : records.length,
            (i) {
              final record = records[records.length - 1 - i]; // Reverse: newest first
              final isLast =
                  i == (records.length > 10 ? 9 : records.length - 1);
              final isCurrent = i == 0;
              return _buildLocationTile(record, isLast, isCurrent);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Container(
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
                        Text(
                          coords,
                          style: TextStyle(
                            fontSize: scaledFontSize(14, screenWidth),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: scaledFontSize(10, screenWidth),
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
