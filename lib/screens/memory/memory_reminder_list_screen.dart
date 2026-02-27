import 'package:flutter/material.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory Reminder list screen with cards and bottom create button.
class MemoryReminderListScreen extends StatelessWidget {
  const MemoryReminderListScreen({super.key});

  // Placeholder data
  static final _reminders = [
    _ReminderData(
      name: 'Living Room Photo',
      lat: 37.7749,
      lng: -122.4194,
      hasPhoto: true,
      hasAudio: true,
      hasVideo: false,
    ),
    _ReminderData(
      name: 'Park Entrance',
      lat: 37.7694,
      lng: -122.4862,
      hasPhoto: true,
      hasAudio: false,
      hasVideo: true,
    ),
    _ReminderData(
      name: 'Grocery Store',
      lat: 37.7849,
      lng: -122.4094,
      hasPhoto: false,
      hasAudio: true,
      hasVideo: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Memory Reminders',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: _reminders.isEmpty ? _buildEmpty(context) : _buildList(context),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GradientButtonWithIcon(
            text: 'Create Memory Reminder',
            icon: Icons.add,
            onPressed: () {
              Navigator.pushNamed(context, Routes.createMemory);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 64,
            color: AppColors.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No memory reminders yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create one',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (_, i) => _ReminderCard(data: _reminders[i]),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final _ReminderData data;
  const _ReminderCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo placeholder
          if (data.hasPhoto)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.secondaryContainerColor,
                child: const Center(
                  child: Icon(
                    Icons.photo,
                    size: 48,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data.lat}, ${data.lng}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Media chips
                Wrap(
                  spacing: 8,
                  children: [
                    if (data.hasPhoto) _mediaChip(Icons.photo_camera, 'Photo'),
                    if (data.hasAudio) _mediaChip(Icons.mic, 'Audio'),
                    if (data.hasVideo) _mediaChip(Icons.videocam, 'Video'),
                  ],
                ),
                const SizedBox(height: 12),

                // Delete button
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete, color: AppColors.errorColor),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.errorColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderData {
  final String name;
  final double lat;
  final double lng;
  final bool hasPhoto;
  final bool hasAudio;
  final bool hasVideo;

  const _ReminderData({
    required this.name,
    required this.lat,
    required this.lng,
    required this.hasPhoto,
    required this.hasAudio,
    required this.hasVideo,
  });
}
