import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/theme/responsive.dart';
import 'package:relapse_flutter/widgets/common/gradient_text.dart';
import 'package:relapse_flutter/widgets/common/gradient_icon.dart';

/// Reusable section header with gradient icon, title, and underline bar.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final double screenWidth;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GradientIcon(icon, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientText(
              title,
              style: TextStyle(
                fontSize: scaledFontSize(18, screenWidth),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                gradient: AppGradients.iconText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
