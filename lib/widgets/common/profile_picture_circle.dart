import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';

/// Profile picture circle with camera button overlay (120×120).
class ProfilePictureCircle extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onCameraTap;

  const ProfilePictureCircle({
    super.key,
    this.imageUrl,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: AppColors.gradientMiddle,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                onPressed: onCameraTap ?? () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Icon(Icons.person, size: 60, color: Colors.grey[400]);
  }
}
