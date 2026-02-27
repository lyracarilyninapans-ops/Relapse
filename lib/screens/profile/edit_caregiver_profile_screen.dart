import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/patient_profile_ui_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Edit Caregiver Profile screen.
class EditCaregiverProfileScreen extends ConsumerWidget {
  const EditCaregiverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(editCaregiverNameProvider);
    final phone = ref.watch(editCaregiverPhoneProvider);
    final bio = ref.watch(editCaregiverBioProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Your Profile'),
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
              const ProfilePictureCircle(),
              const SizedBox(height: 32),

              // Email (read-only)
              TextFormField(
                initialValue: 'john.caregiver@email.com',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
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
                  ref.read(editCaregiverNameProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (Optional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
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
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  ref.read(editCaregiverPhoneProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                initialValue: bio,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
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
                  ref.read(editCaregiverBioProvider.notifier).state = value;
                },
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientMiddle,
                      AppColors.gradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gradientMiddle.withAlpha(100),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: const Center(
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
