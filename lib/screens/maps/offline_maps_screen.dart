import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/connectivity_providers.dart';
import 'package:relapse_flutter/providers/safe_zone_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Offline Maps Setup screen with instructions, safe zone info, and confirmation.
class OfflineMapsScreen extends ConsumerStatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  ConsumerState<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends ConsumerState<OfflineMapsScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final primaryZone = ref.watch(primarySafeZoneProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Offline Maps Setup',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorColor.withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.errorColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Offline maps are essential for safe zone navigation when the watch has no internet.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Connectivity status
            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You are currently offline. Connect to download maps.',
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Recommended region based on safe zone
            if (primaryZone != null) ...[
              _sectionCard(
                icon: Icons.my_location,
                title: 'Recommended Region',
                content:
                    'Based on your safe zone configuration, download the map area around:\n\n'
                    'Center: ${primaryZone.centerLat.toStringAsFixed(4)}, '
                    '${primaryZone.centerLng.toStringAsFixed(4)}\n'
                    'Radius: ${primaryZone.radiusMeters.round()}m\n\n'
                    'We recommend downloading at least a 5 km radius around this point.',
              ),
              const SizedBox(height: 20),
            ],

            // Why Offline Maps
            _sectionCard(
              icon: Icons.info_outline,
              title: 'Why Offline Maps?',
              content:
                  'Offline maps ensure the patient\'s watch can provide navigation even in areas '
                  'with poor or no internet connectivity. This is critical for safe zone functionality '
                  'to guide the patient back home.',
            ),
            const SizedBox(height: 20),

            // What to Download
            _sectionCard(
              icon: Icons.download,
              title: 'What to Download',
              content:
                  'Download the map area covering the safe zone plus a buffer zone around it. '
                  'This typically includes a 2-5 km radius around the safe zone center.',
            ),
            const SizedBox(height: 20),

            // How to Download
            _sectionCard(
              icon: Icons.help_outline,
              title: 'How to Download',
              content: '1. Open Google Maps on the watch\n'
                  '2. Navigate to the safe zone area\n'
                  '3. Tap "Download offline map"\n'
                  '4. Select the area and confirm download\n'
                  '5. Wait for the download to complete',
            ),
            const SizedBox(height: 24),

            // Open Google Maps button
            GradientButtonWithIcon(
              text: 'Open Google Maps',
              icon: Icons.map,
              onPressed: () {
                if (primaryZone != null) {
                  _showSafeZoneLocationInfo(
                    context,
                    primaryZone.centerLat,
                    primaryZone.centerLng,
                    primaryZone.radiusMeters,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No safe zone configured yet. Set up a safe zone first.',
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Confirmation checkbox
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _confirmed,
                activeColor: AppColors.primaryColor,
                checkColor: Colors.white,
                title: const Text('I have downloaded offline maps'),
                subtitle: const Text(
                  'Confirm that you have downloaded the required offline map area',
                ),
                onChanged: (val) {
                  setState(() => _confirmed = val ?? false);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Confirm button
            GradientButtonWithIcon(
              text: 'Confirm & Continue',
              icon: Icons.check_circle,
              onPressed: _confirmed ? () => Navigator.pop(context) : null,
            ),
            const SizedBox(height: 16),

            // Skip button
            Center(
              child: TextButton(
                onPressed: () {
                  _showSkipWarning(context);
                },
                child: Text(
                  'Skip for now (Not Recommended)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showSafeZoneLocationInfo(
    BuildContext context,
    double lat,
    double lng,
    double radius,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text('Safe Zone Location'),
        content: Text(
          'Center your offline map download around these coordinates:\n\n'
          'Latitude: ${lat.toStringAsFixed(6)}\n'
          'Longitude: ${lng.toStringAsFixed(6)}\n'
          'Safe zone radius: ${radius.round()}m\n\n'
          'Download at least a 5 km area around this point in Google Maps.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSkipWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text(
          'Skip Offline Maps?',
          style: TextStyle(color: AppColors.errorColor),
        ),
        content: const Text(
          'Without offline maps, the watch may not be able to navigate the patient back '
          'to the safe zone when internet connectivity is poor. This could put the patient at risk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Go Back',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back
            },
            child: const Text(
              'Skip Anyway',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
