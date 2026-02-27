import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory details screen showing photo, location, audio/video sections.
class MemoryDetailsScreen extends StatelessWidget {
  const MemoryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Living Room Photo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder with pinch-to-zoom
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Container(
                    color: AppColors.secondaryContainerColor,
                    child: const Center(
                      child: Icon(
                        Icons.photo,
                        size: 64,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location row
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppColors.secondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '37.7749, -122.4194',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Audio section placeholder
            Text(
              'Audio Reminder',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryContainerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.audiotrack, color: AppColors.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Audio playback placeholder',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video section placeholder
            Text(
              'Video Reminder',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryContainerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 48,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video playback placeholder',
                      style: TextStyle(color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
