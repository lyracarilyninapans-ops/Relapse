import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/data/remote/memory_reminder_remote_source.dart';
import 'package:relapse_flutter/models/memory_reminder.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';

// ─── Remote Source ───────────────────────────────────────────────────────

final memoryReminderRemoteSourceProvider =
    Provider<MemoryReminderRemoteSource>((ref) {
  return MemoryReminderRemoteSource();
});

// ─── Memory Reminders Stream ─────────────────────────────────────────────

/// Stream of all memory reminders for the selected patient.
final memoryRemindersProvider = StreamProvider<List<MemoryReminder>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final patientId = ref.watch(selectedPatientIdProvider);
  if (authUser == null || patientId == null) return const Stream.empty();
  return ref
      .watch(memoryReminderRemoteSourceProvider)
      .watchReminders(authUser.uid, patientId);
});

/// Active (non-deleted) memory reminders.
final activeMemoryRemindersProvider = Provider<List<MemoryReminder>>((ref) {
  final reminders = ref.watch(memoryRemindersProvider).valueOrNull ?? [];
  return reminders.where((r) => r.isActive).toList();
});

/// Count of active memory reminders (used by home screen quick stats).
final memoryReminderCountProvider = Provider<int>((ref) {
  return ref.watch(activeMemoryRemindersProvider).length;
});
