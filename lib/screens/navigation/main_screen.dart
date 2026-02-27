import 'package:flutter/material.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/screens/home/home_screen.dart';
import 'package:relapse_flutter/screens/memory/memory_screen.dart';
import 'package:relapse_flutter/screens/safe_zone/safe_zone_map_screen.dart';
import 'package:relapse_flutter/screens/activity/activity_screen.dart';
import 'package:relapse_flutter/widgets/navigation/custom_bottom_navigation_bar.dart';

/// Main shell screen with IndexedStack and bottom navigation.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          MemoryScreen(),
          SafeZoneMapScreen(),
          ActivityScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
