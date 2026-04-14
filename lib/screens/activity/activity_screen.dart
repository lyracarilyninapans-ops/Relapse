import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/screens/activity/widgets/activity_current_location_card.dart';
import 'package:relapse_flutter/screens/activity/widgets/activity_feed_widgets.dart';
import 'package:relapse_flutter/screens/activity/widgets/activity_summary_widgets.dart';
import 'package:relapse_flutter/utils/date_range.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Activity monitoring screen with location overview, daily summary,
/// recent activity feed, and location history.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
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
            ActivityDateFilterRow(
              selectedIndex: filter.index,
              onSelected: (i) {
                ref.read(selectedDateRangeFilterProvider.notifier).state =
                    DateRangeFilter.values[i];
              },
            ),
            const SizedBox(height: 20),

            // ── Current Location Card ──
            ActivityCurrentLocationCard(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Daily Summary ──
            SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'DAILY SUMMARY',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            ActivityDailySummaryRow(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Activity Chart ──
            SectionHeader(
              icon: Icons.show_chart_outlined,
              title: 'MOVEMENT PATTERN',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            ActivityMovementChartCard(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Recent Activity Feed ──
            SectionHeader(
              icon: Icons.notifications_outlined,
              title: 'RECENT ACTIVITY',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            ActivityRecentActivityFeed(screenWidth: sw),
            const SizedBox(height: 28),

            // ── Location History ──
            SectionHeader(
              icon: Icons.location_on_outlined,
              title: 'LOCATION HISTORY',
              screenWidth: sw,
            ),
            const SizedBox(height: 16),
            ActivityLocationHistoryTimeline(screenWidth: sw),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


