import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/activity_providers.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/providers/watch_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Home screen with patient overview, quick stats, and feature grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final patient = ref.watch(selectedPatientProvider);
    final hasPatient = patient != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(context, ref),
      body: hasPatient
          ? _buildWithPatient(context, sw, ref)
          : _buildNoPatient(context, sw),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final initial = (authUser?.displayName?.isNotEmpty == true)
        ? authUser!.displayName![0].toUpperCase()
        : (authUser?.email.isNotEmpty == true)
            ? authUser!.email[0].toUpperCase()
            : '?';

    return AppBar(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppGradients.iconText.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            blendMode: BlendMode.srcIn,
            child: Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              color: Colors.white,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.favorite, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const GradientText(
            'Relapse',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'settings':
                Navigator.pushNamed(context, Routes.settings);
                break;
              case 'profile':
                Navigator.pushNamed(context, Routes.editCaregiver);
                break;
              case 'logout':
                try {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sign out failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            radius: 18,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── With patient linked ──────────────────────────────────────────
  Widget _buildWithPatient(BuildContext context, double sw, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const _WatchStatusBanner(),
          const SizedBox(height: 16),
          SectionHeader(
            icon: Icons.person_outline,
            title: 'PATIENT OVERVIEW',
            screenWidth: sw,
          ),
          const SizedBox(height: 16),
          _PatientOverviewCard(screenWidth: sw),
          const SizedBox(height: 32),
          _QuickStatsRow(screenWidth: sw),
          const SizedBox(height: 32),
          SectionHeader(
            icon: Icons.dashboard_outlined,
            title: 'QUICK ACTIONS',
            screenWidth: sw,
          ),
          const SizedBox(height: 16),
          _FeatureGrid(screenWidth: sw),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── No patient linked ────────────────────────────────────────────
  Widget _buildNoPatient(BuildContext context, double sw) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppGradients.iconText,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_outlined,
              size: 80,
              color: AppColors.gradientMiddle,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Patient Linked',
            style: TextStyle(
              fontSize: scaledFontSize(28, sw),
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Link a patient device to start monitoring their location and managing memory cues.',
            style: TextStyle(
              fontSize: scaledFontSize(16, sw),
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          CtaButton(
            text: 'Add Patient',
            icon: Icons.add_circle_outline,
            onPressed: () => Navigator.pushNamed(context, Routes.addPatient),
          ),
        ],
      ),
    );
  }
}

// ─── Watch Status Banner ──────────────────────────────────────────────
class _WatchStatusBanner extends ConsumerWidget {
  const _WatchStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = ref.watch(watchConnectedProvider);
    final battery = ref.watch(watchBatteryProvider);

    final baseColor = connected
        ? AppColors.watchConnected
        : AppColors.watchDisconnected;
    final icon = connected ? Icons.watch : Icons.watch_off;
    final title = connected ? 'Watch Connected' : 'Watch Offline';
    final message = connected
        ? 'Patient device is online and reporting.${battery != null ? ' Battery: $battery%' : ''}'
        : 'Patient device is not reachable.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withAlpha(102), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: baseColor.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: baseColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: baseColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Patient Overview Card ────────────────────────────────────────────
class _PatientOverviewCard extends ConsumerWidget {
  final double screenWidth;
  const _PatientOverviewCard({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(selectedPatientProvider);
    final szStatus = ref.watch(safeZoneStatusProvider);
    final liveLocation = ref.watch(liveLocationProvider);

    final name = patient?.name ?? 'Unknown';
    final initials = name.isNotEmpty
        ? name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    final updatedText = liveLocation.when(
      data: (record) {
        if (record == null) return 'No location data';
        final diff = DateTime.now().difference(record.timestamp);
        if (diff.inMinutes < 1) return 'Updated just now';
        if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
        return '${diff.inHours}h ago';
      },
      loading: () => 'Loading...',
      error: (_, __) => 'Unavailable',
    );

    final isInside = szStatus == SafeZoneStatus.inside;
    final szLabel = switch (szStatus) {
      SafeZoneStatus.inside => 'Inside Safe Zone',
      SafeZoneStatus.outside => 'Outside Safe Zone',
      SafeZoneStatus.unknown => 'Status Unknown',
    };
    final szColors = isInside
        ? [AppColors.safeZoneInsideStart, AppColors.safeZoneInsideEnd]
        : [AppColors.safeZoneOutsideStart, AppColors.safeZoneOutsideEnd];

    final avatarSize = (screenWidth * 0.20).clamp(64.0, 140.0);

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardBorder,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.cardBorder,
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryContainerColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: avatarSize * 0.35,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: scaledFontSize(20, screenWidth),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        updatedText,
                        style: TextStyle(
                          fontSize: scaledFontSize(12, screenWidth),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: szColors),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: szColors.first.withAlpha(102),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          szLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.editPatient);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Stats Row ──────────────────────────────────────────────────
class _QuickStatsRow extends ConsumerWidget {
  final double screenWidth;
  const _QuickStatsRow({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dailySummaryProvider);

    final activityCount = summary.when(
      data: (s) => s?.totalEvents.toString() ?? '0',
      loading: () => '...',
      error: (_, __) => '--',
    );

    final safeZonesAsync = ref.watch(safeZoneConfigProvider);
    final safeZoneCount = safeZonesAsync.when(
      data: (zones) => zones.length.toString(),
      loading: () => '...',
      error: (_, __) => '--',
    );

    return Row(
      children: [
        _StatCard(
          icon: Icons.photo_library_outlined,
          count: '--',
          label: 'Memories',
          color: AppColors.gradientStart,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.show_chart_outlined,
          count: activityCount,
          label: 'Activity',
          color: AppColors.gradientMiddle,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.location_on_outlined,
          count: safeZoneCount,
          label: 'Safe Zones',
          color: AppColors.gradientEnd,
          screenWidth: screenWidth,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final double screenWidth;

  const _StatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: scaledFontSize(24, screenWidth),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: scaledFontSize(12, screenWidth),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Grid ─────────────────────────────────────────────────────
class _FeatureGrid extends StatelessWidget {
  final double screenWidth;

  const _FeatureGrid({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.cloud_upload_outlined,
        title: 'Upload Memory Cues',
        subtitle: 'Photos, Audio, Video',
        onTap: () => Navigator.pushNamed(context, Routes.memoryReminders),
      ),
      _FeatureItem(
        icon: Icons.shield_outlined,
        title: 'Set Safe Zone',
        subtitle: 'Define Geo-Boundary',
        onTap: () => Navigator.pushNamed(context, Routes.safeZoneConfig),
      ),
      _FeatureItem(
        icon: Icons.show_chart_outlined,
        title: 'Activity Monitoring',
        subtitle: 'Location History',
        onTap: () {},
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: features.map((f) => _buildFeatureCard(f)).toList(),
    );
  }

  Widget _buildFeatureCard(_FeatureItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gradientStart.withAlpha(26),
                      AppColors.gradientMiddle.withAlpha(26),
                      AppColors.gradientEnd.withAlpha(26),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GradientIcon(item.icon, size: 32),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: scaledFontSize(15, screenWidth),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: TextStyle(
                  fontSize: scaledFontSize(11, screenWidth),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
