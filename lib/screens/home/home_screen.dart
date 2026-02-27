import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Home screen with patient overview, quick stats, and feature grid.
class HomeScreen extends StatelessWidget {
  /// Set to true to show the "no patient linked" state.
  final bool hasPatient;

  const HomeScreen({super.key, this.hasPatient = true});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _buildAppBar(context),
      body: hasPatient
          ? _buildWithPatient(context, sw)
          : _buildNoPatient(context, sw),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.pushNamed(context, '/settings');
                break;
              case 'profile':
                Navigator.pushNamed(context, '/edit-caregiver');
                break;
              case 'logout':
                Navigator.pushReplacementNamed(context, '/login');
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
            child: const Text(
              'J',
              style: TextStyle(
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
  Widget _buildWithPatient(BuildContext context, double sw) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _WatchStatusBanner(connected: true),
          const SizedBox(height: 16),
          _SectionHeader(
            icon: Icons.person_outline,
            title: 'PATIENT OVERVIEW',
            screenWidth: sw,
          ),
          const SizedBox(height: 16),
          _PatientOverviewCard(screenWidth: sw),
          const SizedBox(height: 32),
          _QuickStatsRow(screenWidth: sw),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: Icons.dashboard_outlined,
            title: 'QUICK ACTIONS',
            screenWidth: sw,
          ),
          const SizedBox(height: 16),
          _FeatureGrid(screenWidth: sw, context: context),
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
            onPressed: () => Navigator.pushNamed(context, '/add-patient'),
          ),
        ],
      ),
    );
  }
}

// ─── Watch Status Banner ──────────────────────────────────────────────
class _WatchStatusBanner extends StatelessWidget {
  final bool connected;
  const _WatchStatusBanner({required this.connected});

  @override
  Widget build(BuildContext context) {
    final baseColor = connected
        ? AppColors.watchConnected
        : AppColors.watchDisconnected;
    final icon = connected ? Icons.watch : Icons.watch_off;
    final title = connected ? 'Watch Connected' : 'Watch Offline';
    final message = connected
        ? 'Patient device is online and reporting.'
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

// ─── Section Header ───────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final double screenWidth;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GradientIcon(icon, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientText(
              title,
              style: TextStyle(
                fontSize: scaledFontSize(18, screenWidth),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                gradient: AppGradients.iconText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Patient Overview Card ────────────────────────────────────────────
class _PatientOverviewCard extends StatelessWidget {
  final double screenWidth;
  const _PatientOverviewCard({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
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
                    'JD',
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
                    'John Doe',
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
                        '5 min ago',
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
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.safeZoneInsideStart,
                          AppColors.safeZoneInsideEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.safeZoneInsideStart.withAlpha(102),
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
                        const Text(
                          'Inside Safe Zone',
                          style: TextStyle(
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
                  Navigator.pushNamed(context, '/edit-patient');
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
class _QuickStatsRow extends StatelessWidget {
  final double screenWidth;
  const _QuickStatsRow({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.photo_library_outlined,
          count: '12',
          label: 'Memories',
          color: AppColors.gradientStart,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.show_chart_outlined,
          count: '8',
          label: 'Activity',
          color: AppColors.gradientMiddle,
          screenWidth: screenWidth,
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.location_on_outlined,
          count: '2',
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
  final BuildContext context;

  const _FeatureGrid({required this.screenWidth, required this.context});

  @override
  Widget build(BuildContext _) {
    final features = [
      _FeatureItem(
        icon: Icons.cloud_upload_outlined,
        title: 'Upload Memory Cues',
        subtitle: 'Photos, Audio, Video',
        onTap: () => Navigator.pushNamed(context, '/memory-reminders'),
      ),
      _FeatureItem(
        icon: Icons.shield_outlined,
        title: 'Set Safe Zone',
        subtitle: 'Define Geo-Boundary',
        onTap: () {},
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
