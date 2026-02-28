import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:relapse_flutter/models/media_item.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/memory_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Memory details screen showing photo, location, audio/video sections.
class MemoryDetailsScreen extends ConsumerStatefulWidget {
  const MemoryDetailsScreen({super.key});

  @override
  ConsumerState<MemoryDetailsScreen> createState() =>
      _MemoryDetailsScreenState();
}

class _MemoryDetailsScreenState extends ConsumerState<MemoryDetailsScreen> {
  AudioPlayer? _audioPlayer;
  VideoPlayerController? _videoController;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _videoInitialized = false;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _initAudioPlayer(String url) {
    if (_audioPlayer != null) return;
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _audioPlayer!.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer!.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isAudioPlaying = false);
    });
    _audioPlayer!.setSourceUrl(url);
  }

  void _initVideoPlayer(String url) {
    if (_videoController != null) return;
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) setState(() => _videoInitialized = true);
      });
  }

  Future<void> _toggleAudio(String url) async {
    _initAudioPlayer(url);
    if (_isAudioPlaying) {
      await _audioPlayer!.pause();
      setState(() => _isAudioPlaying = false);
    } else {
      await _audioPlayer!.play(UrlSource(url));
      setState(() => _isAudioPlaying = true);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
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
              Builder(builder: (context) {
                final audioItem = reminder.mediaItems.firstWhere(
                  (m) => m.type == MediaType.audio,
                );
                final audioUrl = audioItem.cloudUrl;
                if (audioUrl == null || audioUrl.isEmpty) {
                  return Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Audio file not uploaded yet',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                  );
                }
                _initAudioPlayer(audioUrl);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isAudioPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: AppColors.primaryColor,
                              size: 40,
                            ),
                            onPressed: () => _toggleAudio(audioUrl),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                  ),
                                  child: Slider(
                                    value: _audioPosition.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                            0,
                                            _audioDuration.inMilliseconds
                                                .toDouble()
                                                .clamp(1, double.infinity)),
                                    min: 0,
                                    max: _audioDuration.inMilliseconds
                                        .toDouble()
                                        .clamp(1, double.infinity),
                                    activeColor: AppColors.primaryColor,
                                    onChanged: (val) {
                                      _audioPlayer?.seek(
                                          Duration(milliseconds: val.toInt()));
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_audioPosition),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                    Text(
                                      _formatDuration(_audioDuration),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
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
              Builder(builder: (context) {
                final videoItem = reminder.mediaItems.firstWhere(
                  (m) => m.type == MediaType.video,
                );
                final videoUrl = videoItem.cloudUrl;
                if (videoUrl == null || videoUrl.isEmpty) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Video file not uploaded yet',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                  );
                }
                _initVideoPlayer(videoUrl);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _videoInitialized && _videoController != null
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_videoController!),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_videoController!.value.isPlaying) {
                                      _videoController!.pause();
                                    } else {
                                      _videoController!.play();
                                    }
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: AnimatedOpacity(
                                    opacity:
                                        _videoController!.value.isPlaying
                                            ? 0.0
                                            : 1.0,
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.primaryContainerColor,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                );
              }),
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
                      Routes.createMemory,
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
