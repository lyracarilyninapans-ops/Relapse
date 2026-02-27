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

  // Placeholder: set to true when patient is linked
  final bool _hasPatient = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(hasPatient: true),
          const MemoryScreen(),
          _hasPatient
              ? const SafeZoneMapScreen()
              : _buildNoPatientPlaceholder(),
          const ActivityScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildNoPatientPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No Patient Linked',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Link a patient to access safe zone features.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
