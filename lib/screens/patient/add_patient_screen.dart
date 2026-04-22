import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/providers/watch_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

enum _PostClaimAction { createNew, useExisting }

/// Add Patient screen where the caregiver enters the pairing code
/// displayed on the patient's watch.
class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _enteredCode => _digitControllers.map((c) => c.text).join();

  Future<void> _submitCode() async {
    if (_isSubmitting) return;

    final code = _enteredCode;
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final watchId = await ref
          .read(watchServiceProvider)
          .submitPairingCode(authUser.uid, code);

      final patients = ref.read(patientsProvider).valueOrNull ?? const [];
      if (patients.isNotEmpty) {
        final action = await _showPostClaimActionDialog();
        if (!mounted) return;
        if (action == null) {
          setState(() => _isSubmitting = false);
          return;
        }

        if (action == _PostClaimAction.useExisting) {
          final selectedPatient = await _showExistingPatientPicker();
          if (!mounted) return;
          if (selectedPatient == null) {
            setState(() => _isSubmitting = false);
            return;
          }

          await _pairWithExistingPatient(
            uid: authUser.uid,
            watchId: watchId,
            patientId: selectedPatient,
          );
          return;
        }
      }

      if (!mounted) return;
      // Reset explicit selection so setup can establish the new patient context.
      ref.read(selectedPatientIdProvider.notifier).selectPatient(null);
      await Navigator.pushReplacementNamed(
        context,
        Routes.patientSetup,
        arguments: watchId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<_PostClaimAction?> _showPostClaimActionDialog() async {
    return showDialog<_PostClaimAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Pairing'),
        content: const Text(
          'Choose an existing patient to re-pair this watch, or create a new patient profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _PostClaimAction.createNew),
            child: const Text('Create New'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _PostClaimAction.useExisting),
            child: const Text('Use Existing'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showExistingPatientPicker() async {
    final patients = ref.read(patientsProvider).valueOrNull ?? const [];
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Select Existing Patient',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final patient in patients)
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(patient.name),
                  subtitle:
                      patient.pairedWatchId != null &&
                          patient.pairedWatchId!.isNotEmpty
                      ? const Text('Currently has a linked watch')
                      : const Text('No linked watch'),
                  onTap: () => Navigator.pop(ctx, patient.id),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pairWithExistingPatient({
    required String uid,
    required String watchId,
    required String patientId,
  }) async {
    final patientSource = ref.read(patientRemoteSourceProvider);
    final selected = await patientSource.getPatient(uid, patientId);
    if (selected == null) {
      throw Exception('Selected patient could not be loaded');
    }

    final allPatients = ref.read(patientsProvider).valueOrNull ?? const [];
    for (final patient in allPatients) {
      if (patient.id != selected.id &&
          patient.pairedWatchId != null &&
          patient.pairedWatchId!.isNotEmpty) {
        await patientSource.clearPairedWatch(uid, patient.id);
      }
    }

    await patientSource.savePatient(
      uid,
      selected.copyWith(pairedWatchId: watchId),
    );

    await ref
        .read(watchServiceProvider)
        .finalizePairing(
          uid,
          patientName: selected.name,
          patientId: selected.id,
        );

    ref.read(selectedPatientIdProvider.notifier).selectPatient(selected.id);

    if (!mounted) return;
    await Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.main,
      (route) => false,
    );
  }

  void _onDigitChanged(int index, String value) {
    // Avoid rebuilding the whole page on every keystroke.
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 6 digits entered
    if (_enteredCode.length == 6 && !_isSubmitting) {
      _submitCode();
    }
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _digitControllers[index].text.isEmpty &&
        index > 0) {
      _digitControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Patient'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              children: [
            RepaintBoundary(
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
                      Icons.watch_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Enter Watch Code',
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
                        _buildStep(
                          sw,
                          1,
                          'Open Watch App',
                          'Open the Relapse app on the patient\'s watch',
                        ),
                        _buildStep(
                          sw,
                          2,
                          'Find the Code',
                          'A 6-digit code will appear on the watch screen',
                        ),
                        _buildStep(
                          sw,
                          3,
                          'Enter Code Below',
                          'Type the code shown on the watch into the fields below',
                        ),
                        _buildStep(
                          sw,
                          4,
                          'Wait for Connection',
                          'The devices will connect automatically',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Code input fields — gradient-bordered container
            Container(
              padding: const EdgeInsets.all(2),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: AppGradients.cardBorder,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    GradientText(
                      'Pairing Code',
                      style: TextStyle(
                        fontSize: scaledFontSize(14, sw),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (int i = 0; i < 6; i++) ...[
                          if (i == 3) const SizedBox(width: 10),
                          Expanded(child: _buildDigitField(i, sw)),
                          if (i < 5 && i != 2) const SizedBox(width: 6),
                          if (i == 2) const SizedBox(width: 0),
                        ],
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: scaledFontSize(13, sw),
                        ),
                      ),
                    ],
                    if (_isSubmitting) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connecting to watch...',
                            style: TextStyle(
                              fontSize: scaledFontSize(13, sw),
                              color: AppColors.gradientMiddle,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            CtaButton(
              text: 'Connect Watch',
              icon: Icons.link,
              onPressed: _isSubmitting ? null : _submitCode,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 24),

            const RepaintBoundary(
              child: InfoBox(
                text:
                    'Need help? Contact support at support@relapsecare.com for assistance with device pairing.',
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A single digit-entry field wrapped in a gradient border.
  Widget _buildDigitField(int index, double sw) {
    return RepaintBoundary(
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(2),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AppGradients.cardBorder,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Focus(
            onKeyEvent: (_, event) {
              _onKeyPress(index, event);
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _digitControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              scrollPadding: const EdgeInsets.only(bottom: 72),
              maxLength: 1,
              style: TextStyle(
                fontSize: scaledFontSize(24, sw),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _onDigitChanged(index, v),
            ),
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
