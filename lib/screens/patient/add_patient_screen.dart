import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/pairing_info.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/watch_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Add Patient screen with pairing code generation and watch listening.
class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  String? _generatedCode;
  bool _isGenerating = false;
  bool _isWaiting = false;
  StreamSubscription<PairingInfo?>? _pairingSub;

  @override
  void dispose() {
    _pairingSub?.cancel();
    super.dispose();
  }

  Future<void> _generateCode() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() => _isGenerating = true);

    try {
      final code = await ref
          .read(watchServiceProvider)
          .generatePairingCode(authUser.uid);

      if (!mounted) return;
      setState(() {
        _generatedCode = code;
        _isGenerating = false;
        _isWaiting = true;
      });

      // Listen for the watch to pair
      _pairingSub?.cancel();
      _pairingSub = ref
          .read(watchServiceProvider)
          .watchPairingStatus(authUser.uid)
          .listen((info) {
        if (info != null && info.status == PairingStatus.paired && mounted) {
          Navigator.pushReplacementNamed(
            context,
            Routes.patientSetup,
            arguments: info.watchId,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Patient'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                  _buildStep(sw, 1, 'Generate Pairing Code',
                      'Tap the button below to create a code'),
                  _buildStep(sw, 2, 'Open Watch App',
                      'Open the Relapse app on the patient\'s watch'),
                  _buildStep(sw, 3, 'Enter Code on Watch',
                      'Type the generated code on the watch'),
                  _buildStep(sw, 4, 'Wait for Connection',
                      'The devices will connect automatically'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Generated code display
            if (_generatedCode != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: AppGradients.cardBorder,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Pairing Code',
                      style: TextStyle(
                        fontSize: scaledFontSize(14, sw),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedCode!,
                      style: TextStyle(
                        fontSize: scaledFontSize(36, sw),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (_isWaiting) ...[
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
                            'Waiting for watch...',
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
              const SizedBox(height: 24),
            ],

            // Generate / Regenerate button
            CtaButton(
              text: _generatedCode == null
                  ? 'Generate Pairing Code'
                  : 'Regenerate Code',
              icon: _generatedCode == null
                  ? Icons.vpn_key_outlined
                  : Icons.refresh,
              onPressed: _isGenerating ? null : _generateCode,
              isLoading: _isGenerating,
            ),
            const SizedBox(height: 24),

            const InfoBox(
              text:
                  'Need help? Contact support at support@relapsecare.com for assistance with device pairing.',
            ),
          ],
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
