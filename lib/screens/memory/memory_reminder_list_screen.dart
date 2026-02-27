import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/models/media_item.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/memory_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory Reminder list screen with cards and bottom create button.
class MemoryReminderListScreen extends ConsumerWidget {
  const MemoryReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(memoryRemindersProvider);

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
      body: remindersAsync.when(
        data: (reminders) {
          final active = reminders.where((r) => r.isActive).toList();
          if (active.isEmpty) return _buildEmpty(context);
          return _buildList(context, ref, active);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Unable to load reminders',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
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

  Widget _buildList(
      BuildContext context, WidgetRef ref, List<MemoryReminder> reminders) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (_, i) => _ReminderCard(
        reminder: reminders[i],
        onDelete: () => _deleteReminder(context, ref, reminders[i]),
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.memoryDetails,
            arguments: reminders[i].id,
          );
        },
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final MemoryReminder reminder;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = reminder.mediaItems.any((m) => m.type == MediaType.photo);
    final hasAudio = reminder.mediaItems.any((m) => m.type == MediaType.audio);
    final hasVideo = reminder.mediaItems.any((m) => m.type == MediaType.video);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo placeholder or thumbnail
            if (hasPhoto)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildPhotoSection(),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (reminder.latitude != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${reminder.latitude!.toStringAsFixed(4)}, ${reminder.longitude!.toStringAsFixed(4)}',
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
                      if (hasPhoto) _mediaChip(Icons.photo_camera, 'Photo'),
                      if (hasAudio) _mediaChip(Icons.mic, 'Audio'),
                      if (hasVideo) _mediaChip(Icons.videocam, 'Video'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextButton.icon(
                    onPressed: onDelete,
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
      ),
    );
  }

  Widget _buildPhotoSection() {
    final photoItem = reminder.mediaItems.firstWhere(
      (m) => m.type == MediaType.photo,
    );
    if (photoItem.cloudUrl != null && photoItem.cloudUrl!.isNotEmpty) {
      return SizedBox(
        height: 200,
        width: double.infinity,
        child: Image.network(
          photoItem.cloudUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _photoPlaceholder(),
        ),
      );
    }
    return _photoPlaceholder();
  }

  Widget _photoPlaceholder() {
    return Container(
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
