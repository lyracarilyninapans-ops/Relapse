import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';

/// Custom bottom navigation bar with gradient icons for selected state.
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _destinations = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.map_outlined, label: 'Memory'),
    _NavItem(icon: Icons.shield_outlined, label: 'Safe Zone'),
    _NavItem(icon: Icons.show_chart_outlined, label: 'Activity'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: _destinations.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isSelected = i == currentIndex;

          return NavigationDestination(
            icon: isSelected
                ? ShaderMask(
                    shaderCallback: (bounds) =>
                        AppGradients.iconText.createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    blendMode: BlendMode.srcIn,
                    child: Icon(item.icon, color: Colors.white),
                  )
                : Icon(item.icon, color: Colors.grey.shade600),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
