import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/models/patient.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Patient Setup screen shown after successful pairing.
/// Receives optional watchId via route arguments.
class PatientSetupScreen extends ConsumerStatefulWidget {
  const PatientSetupScreen({super.key});

  @override
  ConsumerState<PatientSetupScreen> createState() => _PatientSetupScreenState();
}

class _PatientSetupScreenState extends ConsumerState<PatientSetupScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the patient\'s name')),
      );
      return;
    }

    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() => _isSaving = true);

    try {
      final watchId = ModalRoute.of(context)?.settings.arguments as String?;
      final patient = Patient(
        id: '',
        caregiverUid: authUser.uid,
        name: name,
        age: int.tryParse(_ageController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        pairedWatchId: watchId,
        createdAt: DateTime.now(),
      );

      await ref.read(patientRemoteSourceProvider).savePatient(
            authUser.uid,
            patient,
          );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.main);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save patient: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Setup Patient Profile'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.pushReplacementNamed(context, Routes.main);
                  },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              controller: _nameController,
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
            ),
            const SizedBox(height: 16),

            // Age
            TextFormField(
              controller: _ageController,
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
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
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
            ),
            const SizedBox(height: 32),

            CtaButton(
              text: 'Complete Setup',
              onPressed: _isSaving ? null : _completeSetup,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 16),

            const InfoBox(
              text:
                  'You can update this information anytime from the patient profile settings.',
            ),
          ],
        ),
      ),
    );
  }
}
