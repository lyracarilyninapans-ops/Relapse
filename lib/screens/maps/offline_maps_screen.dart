import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Offline Maps Setup screen with instructions and confirmation.
class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {},
            ),
            const SizedBox(height: 16),

            // Show Safe Zone in Maps button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.location_on, color: AppColors.primaryColor),
                label: const Text(
                  'Show Safe Zone in Maps',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 50),
                ),
              ),
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
