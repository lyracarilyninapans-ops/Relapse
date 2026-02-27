import 'package:flutter/material.dart';
import '../../theme/app_gradients.dart';

/// Full-screen gradient background wrapper.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: child,
    );
  }
}
