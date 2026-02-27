import 'package:flutter/material.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/cta_button.dart';

/// Shared empty-state view shown on tabs when no patient is linked.
class NoPatientLinkedView extends StatelessWidget {
  final String featureLabel;

  const NoPatientLinkedView({super.key, required this.featureLabel});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppGradients.iconText,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Patient Linked',
              style: TextStyle(
                fontSize: scaledFontSize(24, sw),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Link a patient device to access $featureLabel.',
              style: TextStyle(
                fontSize: scaledFontSize(15, sw),
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CtaButton(
              text: 'Add Patient',
              icon: Icons.add_circle_outline,
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.addPatient),
            ),
          ],
        ),
      ),
    );
  }
}
