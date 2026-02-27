import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/patient_profile_ui_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Edit Patient Profile screen.
class EditPatientProfileScreen extends ConsumerWidget {
  const EditPatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(editPatientNameProvider);
    final age = ref.watch(editPatientAgeProvider);
    final notes = ref.watch(editPatientNotesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Patient Profile'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile picture
              const ProfilePictureCircle(
                // Placeholder: no image
              ),
              const SizedBox(height: 32),

              // Name
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Patient Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gradientMiddle,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  ref.read(editPatientNameProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                initialValue: age,
                decoration: InputDecoration(
                  labelText: 'Age (Optional)',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gradientMiddle,
                      width: 2,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  ref.read(editPatientAgeProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                initialValue: notes,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  filled: true,
                  fillColor: AppColors.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gradientMiddle,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  ref.read(editPatientNotesProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 32),

              CtaButton(
                text: 'Save Changes',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
