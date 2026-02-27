import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Activity monitoring screen with location overview, daily summary,
/// recent activity feed, and location history.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _selectedFilter = 0; // 0=Today, 1=This Week, 2=This Month

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

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
            onPressed: () {
              // TODO: open date range picker
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
              selectedIndex: _selectedFilter,
              onSelected: (i) => setState(() => _selectedFilter = i),
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
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
class _CurrentLocationCard extends StatelessWidget {
  final double screenWidth;
  const _CurrentLocationCard({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
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
                  // Grid lines for map feel
                  ..._buildGridLines(),
                  // Center pin
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
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                          '123 Maple Street, Home',
                          style: TextStyle(
                            fontSize: scaledFontSize(15, screenWidth),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updated 2 min ago',
                              style: TextStyle(
                                fontSize: scaledFontSize(12, screenWidth),
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.safeZoneInsideStart.withAlpha(
                                  26,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Safe Zone',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.safeZoneInsideStart,
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
      // Horizontal lines
      for (int i = 1; i < 4; i++)
        Positioned(
          top: i * 40.0,
          left: 0,
          right: 0,
          child: Container(
            height: 0.5,
            color: AppColors.gradientMiddle.withAlpha(30),
          ),
        ),
      // Vertical lines
      for (int i = 1; i < 6; i++)
        Positioned(
          left: i * 70.0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 0.5,
            color: AppColors.gradientMiddle.withAlpha(30),
          ),
        ),
    ];
  }
}

// ─── Daily Summary Row ────────────────────────────────────────────────
class _DailySummaryRow extends StatelessWidget {
  final double screenWidth;
  const _DailySummaryRow({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
          icon: Icons.directions_walk,
          value: '1.2 km',
          label: 'Distance',
          color: AppColors.gradientStart,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          icon: Icons.timer_outlined,
          value: '3h 20m',
          label: 'Time Outside',
          color: AppColors.gradientMiddle,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _SummaryCard(
          icon: Icons.place_outlined,
          value: '4',
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
class _MovementChartCard extends StatelessWidget {
  final double screenWidth;
  const _MovementChartCard({required this.screenWidth});

  // Mock hourly data (24 hours, values 0.0–1.0 representing activity level)
  static const _hourlyData = [
    0.0, 0.0, 0.0, 0.0, 0.0, 0.05, // 00–05
    0.1, 0.3, 0.6, 0.8, 0.65, 0.5, // 06–11
    0.4, 0.3, 0.55, 0.7, 0.6, 0.35, // 12–17
    0.2, 0.15, 0.1, 0.05, 0.0, 0.0, // 18–23
  ];

  @override
  Widget build(BuildContext context) {
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
          // Legend row
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
                'Peak: 10 AM',
                style: TextStyle(
                  fontSize: scaledFontSize(12, screenWidth),
                  fontWeight: FontWeight.w600,
                  color: AppColors.gradientStart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bar chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final v = _hourlyData[i];
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
          // Hour labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12 AM',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
              Text(
                '6 AM',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
              Text(
                '12 PM',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
              Text(
                '6 PM',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
              Text(
                '12 AM',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity Feed ─────────────────────────────────────────────
class _RecentActivityFeed extends StatelessWidget {
  final double screenWidth;
  const _RecentActivityFeed({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final events = [
      _ActivityEvent(
        icon: Icons.shield_outlined,
        title: 'Entered Safe Zone',
        subtitle: 'Home — 123 Maple Street',
        time: '2:34 PM',
        color: AppColors.safeZoneInsideStart,
        type: _EventType.safeZone,
      ),
      _ActivityEvent(
        icon: Icons.notifications_active_outlined,
        title: 'Memory Reminder Triggered',
        subtitle: 'Morning Routine — Photo album',
        time: '11:00 AM',
        color: AppColors.gradientStart,
        type: _EventType.reminder,
      ),
      _ActivityEvent(
        icon: Icons.check_circle_outline,
        title: 'Routine Completed',
        subtitle: 'Medication — Morning pills',
        time: '9:15 AM',
        color: AppColors.gradientMiddle,
        type: _EventType.routine,
      ),
      _ActivityEvent(
        icon: Icons.warning_amber_outlined,
        title: 'Left Safe Zone',
        subtitle: 'Exited Home boundary',
        time: '8:45 AM',
        color: AppColors.safeZoneOutsideStart,
        type: _EventType.alert,
      ),
      _ActivityEvent(
        icon: Icons.directions_walk,
        title: 'Walking Detected',
        subtitle: 'Heading towards Park Avenue',
        time: '8:40 AM',
        color: AppColors.tertiaryColor,
        type: _EventType.location,
      ),
      _ActivityEvent(
        icon: Icons.check_circle_outline,
        title: 'Routine Completed',
        subtitle: 'Breakfast — Morning meal',
        time: '8:00 AM',
        color: AppColors.gradientMiddle,
        type: _EventType.routine,
      ),
    ];

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
        children: List.generate(events.length, (i) {
          final event = events[i];
          final isLast = i == events.length - 1;
          return _buildEventTile(event, isLast);
        }),
      ),
    );
  }

  Widget _buildEventTile(_ActivityEvent event, bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                // Icon circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: event.color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(event.icon, size: 20, color: event.color),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: scaledFontSize(14, screenWidth),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.subtitle,
                        style: TextStyle(
                          fontSize: scaledFontSize(12, screenWidth),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Time
                Text(
                  event.time,
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
}

enum _EventType { safeZone, reminder, routine, alert, location }

class _ActivityEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final _EventType type;

  const _ActivityEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.type,
  });
}

// ─── Location History Timeline ────────────────────────────────────────
class _LocationHistoryTimeline extends StatelessWidget {
  final double screenWidth;
  const _LocationHistoryTimeline({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final locations = [
      _LocationEntry(
        name: 'Home',
        address: '123 Maple Street',
        time: '2:34 PM — Now',
        duration: '45 min',
        icon: Icons.home_outlined,
        isCurrent: true,
      ),
      _LocationEntry(
        name: 'Central Park',
        address: '59th St, New York',
        time: '1:20 PM — 2:30 PM',
        duration: '1h 10m',
        icon: Icons.park_outlined,
      ),
      _LocationEntry(
        name: 'Sunrise Pharmacy',
        address: '45 Oak Avenue',
        time: '12:50 PM — 1:15 PM',
        duration: '25 min',
        icon: Icons.local_pharmacy_outlined,
      ),
      _LocationEntry(
        name: 'Home',
        address: '123 Maple Street',
        time: '8:00 AM — 12:45 PM',
        duration: '4h 45m',
        icon: Icons.home_outlined,
      ),
    ];

    return Column(
      children: List.generate(locations.length, (i) {
        final loc = locations[i];
        final isLast = i == locations.length - 1;
        return _buildLocationTile(loc, isLast);
      }),
    );
  }

  Widget _buildLocationTile(_LocationEntry loc, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline track
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: loc.isCurrent ? AppGradients.button : null,
                    color: loc.isCurrent ? null : Colors.grey.shade300,
                    boxShadow: loc.isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.gradientStart.withAlpha(80),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: loc.isCurrent
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
                      color: loc.isCurrent
                          ? AppColors.gradientStart.withAlpha(26)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      loc.icon,
                      size: 22,
                      color: loc.isCurrent
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
                          loc.name,
                          style: TextStyle(
                            fontSize: scaledFontSize(14, screenWidth),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.address,
                          style: TextStyle(
                            fontSize: scaledFontSize(11, screenWidth),
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loc.time,
                          style: TextStyle(
                            fontSize: scaledFontSize(10, screenWidth),
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loc.duration,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
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

class _LocationEntry {
  final String name;
  final String address;
  final String time;
  final String duration;
  final IconData icon;
  final bool isCurrent;

  const _LocationEntry({
    required this.name,
    required this.address,
    required this.time,
    required this.duration,
    required this.icon,
    this.isCurrent = false,
  });
}
