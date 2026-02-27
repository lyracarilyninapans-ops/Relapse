import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/patient_profile_ui_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Patient Setup screen shown after successful pairing.
class PatientSetupScreen extends ConsumerWidget {
  const PatientSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final name = ref.watch(patientSetupNameProvider);
    final age = ref.watch(patientSetupAgeProvider);
    final notes = ref.watch(patientSetupNotesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Setup Patient Profile'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/main');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Success icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryAction,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Patient Linked Successfully!',
                style: TextStyle(
                  fontSize: scaledFontSize(24, sw),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                "Now let's set up their profile",
                style: TextStyle(
                  fontSize: scaledFontSize(16, sw),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Profile picture
              const ProfilePictureCircle(),
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
                  ref.read(patientSetupNameProvider.notifier).state = value;
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
                  ref.read(patientSetupAgeProvider.notifier).state = value;
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
                  ref.read(patientSetupNotesProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 32),

              CtaButton(
                text: 'Complete Setup',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/main');
                },
              ),
              const SizedBox(height: 16),

              const InfoBox(
                text: 'You can update this information anytime from the patient profile settings.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
