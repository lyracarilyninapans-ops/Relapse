import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/patient_profile_ui_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Add Patient screen with pairing code input and instructions.
class AddPatientScreen extends ConsumerWidget {
  const AddPatientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.of(context).size.width;
    final pairingCode = ref.watch(addPatientPairingCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Patient'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Header icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppGradients.primaryAction,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Link Patient Device',
                style: TextStyle(
                  fontSize: scaledFontSize(24, sw),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Instructions card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.gradientStart.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.watch,
                            color: AppColors.gradientStart,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Setup Instructions',
                          style: TextStyle(
                            fontSize: scaledFontSize(18, sw),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Steps
                    _buildStep(sw, 1, 'Open Watch App',
                        'Open the Relapse app on the patient\'s watch'),
                    _buildStep(sw, 2, 'Navigate to Settings',
                        'Go to Device > Pairing section'),
                    _buildStep(sw, 3, 'Find Pairing Code',
                        'The 6-digit code will be displayed'),
                    _buildStep(sw, 4, 'Enter Code Below',
                        'Type the code in the field below'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Pairing code input
              TextFormField(
                textAlign: TextAlign.center,
                maxLength: 6,
                initialValue: pairingCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: 'Pairing Code',
                  hintText: 'Enter 6-digit code',
                  prefixIcon: const Icon(Icons.pin_outlined),
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
                  ref.read(addPatientPairingCodeProvider.notifier).state =
                      value;
                },
              ),
              const SizedBox(height: 32),

              // Link button
              CtaButton(
                text: 'Link Patient',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.patientSetup);
                },
              ),
              const SizedBox(height: 24),

              const InfoBox(
                text:
                    'Need help? Contact support at support@relapsecare.com for assistance with device pairing.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(double sw, int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: AppGradients.button,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: scaledFontSize(14, sw),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: scaledFontSize(12, sw),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
