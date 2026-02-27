import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Edit Patient Profile screen — loads current patient data, saves to Firestore.
class EditPatientProfileScreen extends ConsumerStatefulWidget {
  const EditPatientProfileScreen({super.key});

  @override
  ConsumerState<EditPatientProfileScreen> createState() =>
      _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState
    extends ConsumerState<EditPatientProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _notesCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final patient = ref.read(selectedPatientProvider);
    _nameCtrl = TextEditingController(text: patient?.name ?? '');
    _ageCtrl = TextEditingController(text: patient?.age?.toString() ?? '');
    _notesCtrl = TextEditingController(text: patient?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient name is required')),
      );
      return;
    }

    final authUser = ref.read(authStateProvider).valueOrNull;
    final patient = ref.read(selectedPatientProvider);
    if (authUser == null || patient == null) return;

    setState(() => _isSaving = true);

    try {
      final ageText = _ageCtrl.text.trim();
      final updated = patient.copyWith(
        name: name,
        age: ageText.isNotEmpty ? int.tryParse(ageText) : null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await ref
          .read(patientRemoteSourceProvider)
          .savePatient(authUser.uid, updated);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const GradientText(
          'Edit Patient Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.gradientStart),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const ProfilePictureCircle(),
            const SizedBox(height: 32),

            // Name
            TextFormField(
              controller: _nameCtrl,
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
              controller: _ageCtrl,
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
              controller: _notesCtrl,
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

            GradientButtonWithIcon(
              text: 'Save Changes',
              icon: Icons.save,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
