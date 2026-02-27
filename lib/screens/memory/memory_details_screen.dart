import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/media_item.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/memory_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory details screen showing photo, location, audio/video sections.
class MemoryDetailsScreen extends ConsumerWidget {
  const MemoryDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderId = ModalRoute.of(context)?.settings.arguments as String?;
    final remindersAsync = ref.watch(memoryRemindersProvider);

    return remindersAsync.when(
      data: (reminders) {
        final matches = reminders.where((r) => r.id == reminderId).toList();
        if (matches.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundColor,
              elevation: 0,
              iconTheme:
                  const IconThemeData(color: AppColors.gradientStart),
            ),
            body: const Center(child: Text('Reminder not found')),
          );
        }
        return _buildContent(context, ref, matches.first);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: const Center(child: Text('Unable to load reminder')),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, MemoryReminder reminder) {
    final hasPhoto =
        reminder.mediaItems.any((m) => m.type == MediaType.photo);
    final hasAudio =
        reminder.mediaItems.any((m) => m.type == MediaType.audio);
    final hasVideo =
        reminder.mediaItems.any((m) => m.type == MediaType.video);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: GradientText(
          reminder.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: hasPhoto
                      ? _buildPhotoView(reminder)
                      : _photoPlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            if (reminder.description != null &&
                reminder.description!.isNotEmpty) ...[
              Text(
                reminder.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceColor,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // Location row
            if (reminder.latitude != null)
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppColors.secondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${reminder.latitude!.toStringAsFixed(4)}, ${reminder.longitude!.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.onSurfaceColor,
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Trigger radius: ${reminder.radiusMeters.round()} meters',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Audio section
            if (hasAudio) ...[
              Text(
                'Audio Reminder',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                        'Audio playback',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Video section
            if (hasVideo) ...[
              Text(
                'Video Reminder',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                        'Video playback',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/create-memory',
                      arguments: reminder.id,
                    );
                  },
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
                  onPressed: () => _deleteReminder(context, ref, reminder),
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

  Widget _buildPhotoView(MemoryReminder reminder) {
    final photoItem = reminder.mediaItems.firstWhere(
      (m) => m.type == MediaType.photo,
    );
    if (photoItem.cloudUrl != null && photoItem.cloudUrl!.isNotEmpty) {
      return Image.network(
        photoItem.cloudUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _photoPlaceholder(),
      );
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.secondaryContainerColor,
      child: const Center(
        child: Icon(
          Icons.photo,
          size: 64,
          color: AppColors.secondaryColor,
        ),
      ),
    );
  }

  Future<void> _deleteReminder(
      BuildContext context, WidgetRef ref, MemoryReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Memory Reminder?'),
        content: Text('This will permanently delete "${reminder.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final authUser = ref.read(authStateProvider).valueOrNull;
    final patientId = ref.read(selectedPatientIdProvider);
    if (authUser == null || patientId == null) return;

    try {
      await ref
          .read(memoryReminderRemoteSourceProvider)
          .deleteReminder(authUser.uid, patientId, reminder.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}
