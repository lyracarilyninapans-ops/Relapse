import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/media_upload_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Edit Caregiver Profile screen — loads current profile, saves to Firestore.
class EditCaregiverProfileScreen extends ConsumerStatefulWidget {
  const EditCaregiverProfileScreen({super.key});

  @override
  ConsumerState<EditCaregiverProfileScreen> createState() =>
      _EditCaregiverProfileScreenState();
}

class _EditCaregiverProfileScreenState
    extends ConsumerState<EditCaregiverProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  bool _isSaving = false;
  File? _pickedPhoto;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(caregiverProfileProvider).valueOrNull;
    final authUser = ref.read(authStateProvider).valueOrNull;
    _nameCtrl = TextEditingController(
      text: profile?.name ?? authUser?.displayName ?? '',
    );
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');
    _existingPhotoUrl = profile?.photoUrl;
  }

  Future<void> _pickProfilePhoto() async {
    final uploadService = ref.read(mediaUploadServiceProvider);
    final file = await uploadService.pickPhoto();
    if (file != null && mounted) {
      setState(() => _pickedPhoto = file);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _existingPhotoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await ref.read(mediaUploadServiceProvider).uploadProfilePhoto(
          file: _pickedPhoto!,
          uid: authUser.uid,
          subPath: 'caregiver',
        );
      }

      await ref.read(userRemoteSourceProvider).updateProfile(authUser.uid, {
        'name': name,
        'phone': _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

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
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const GradientText(
          'Edit Your Profile',
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

            ProfilePictureCircle(
              imageUrl: _pickedPhoto != null ? null : _existingPhotoUrl,
              onCameraTap: _pickProfilePhoto,
            ),
            const SizedBox(height: 32),

            // Email (read-only)
            TextFormField(
              initialValue: authUser?.email ?? '',
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
              controller: _nameCtrl,
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
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
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
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioCtrl,
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
