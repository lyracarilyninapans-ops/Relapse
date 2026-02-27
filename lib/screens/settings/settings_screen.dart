import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/providers/settings_providers.dart';
import 'package:relapse_flutter/providers/watch_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Settings screen with preferences persistence and unpair flow.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _cooldownOptions = [15, 30, 45, 60, 90, 120, 180, 240];
  bool _isUnpairing = false;

  @override
  Widget build(BuildContext context) {
    final cooldown = ref.watch(reminderCooldownProvider);
    final soundEnabled = ref.watch(notificationSoundProvider);
    final dailyReportTime = ref.watch(dailyReportTimeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: const GradientText(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Reminder Cooldown ──────────────────────────────────
              _sectionTitle('Reminder Cooldown'),
              const SizedBox(height: 4),
              Text(
                'Minimum time between memory reminder triggers.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Cooldown (minutes)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _cooldownOptions.contains(cooldown) ? cooldown : 30,
                      isExpanded: true,
                      items: _cooldownOptions
                          .map((val) => DropdownMenuItem(
                                value: val,
                                child: Text('$val minutes'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        ref.read(reminderCooldownProvider.notifier).state = val;
                        ref
                            .read(settingsServiceProvider)
                            .setReminderCooldownMinutes(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Notification Sound ─────────────────────────────────
              _sectionTitle('Notifications'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Notification Sound'),
                  subtitle:
                      const Text('Play sound for alerts and reminders'),
                  value: soundEnabled,
                  activeColor: AppColors.primaryColor,
                  onChanged: (val) {
                    ref.read(notificationSoundProvider.notifier).state = val;
                    ref
                        .read(settingsServiceProvider)
                        .setNotificationSoundEnabled(val);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Daily Report Time ──────────────────────────────────
              _sectionTitle('Daily Report'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.schedule,
                      color: AppColors.primaryColor),
                  title: const Text('Report Time'),
                  subtitle: Text(dailyReportTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: dailyReportTime,
                    );
                    if (picked != null) {
                      ref.read(dailyReportTimeProvider.notifier).state =
                          picked;
                      ref
                          .read(settingsServiceProvider)
                          .setDailyReportTime(picked.hour, picked.minute);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Theme Preference ───────────────────────────────────
              _sectionTitle('Appearance'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _themeOption('System Default', 'system', themeMode),
                    const Divider(height: 1),
                    _themeOption('Light', 'light', themeMode),
                    const Divider(height: 1),
                    _themeOption('Dark', 'dark', themeMode),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Danger Zone ────────────────────────────────────────
              const Divider(),
              const SizedBox(height: 16),
              _sectionTitle('Danger Zone', color: AppColors.errorColor),
              const SizedBox(height: 4),
              Text(
                'Unpairing will disconnect the patient device. All safe zone monitoring will stop.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUnpairing ? null : () => _showUnpairDialog(context),
                  icon: const Icon(Icons.link_off, color: AppColors.errorColor),
                  label: _isUnpairing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Unpair Device',
                          style: TextStyle(color: AppColors.errorColor),
                        ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.onSurfaceColor,
      ),
    );
  }

  Widget _themeOption(String label, String value, String currentValue) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: currentValue,
      activeColor: AppColors.primaryColor,
      onChanged: (val) {
        if (val == null) return;
        ref.read(themeModeProvider.notifier).state = val;
        ref.read(settingsServiceProvider).setThemeMode(val);
      },
    );
  }

  void _showUnpairDialog(BuildContext context) {
    final patient = ref.read(selectedPatientProvider);
    final patientName = patient?.name ?? '';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text(
          'Confirm Unpairing',
          style: TextStyle(color: AppColors.errorColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Type "$patientName" to confirm unpairing:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Patient name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim() == patientName) {
                Navigator.pop(ctx);
                _performUnpair();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Patient name does not match'),
                  ),
                );
              }
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performUnpair() async {
    setState(() => _isUnpairing = true);

    try {
      final authUser = ref.read(authStateProvider).valueOrNull;
      final patient = ref.read(selectedPatientProvider);
      if (authUser == null || patient == null) return;

      // Clear pairing in Firestore directly (copyWith can't set null)
      await ref
          .read(patientRemoteSourceProvider)
          .clearPairedWatch(authUser.uid, patient.id);

      // Unpair the watch via Firestore
      await ref.read(watchServiceProvider).unpairWatch(authUser.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device unpaired successfully')),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.addPatient,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUnpairing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unpair: $e')),
        );
      }
    }
  }
}
