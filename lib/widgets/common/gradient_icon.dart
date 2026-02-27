import 'package:flutter/material.dart';
import '../../theme/app_gradients.dart';

/// Icon rendered with the app's gradient shader.
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const GradientIcon(this.icon, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppGradients.iconText.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}
