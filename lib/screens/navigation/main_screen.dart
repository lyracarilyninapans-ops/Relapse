import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/notification_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/screens/home/home_screen.dart';
import 'package:relapse_flutter/screens/memory/memory_screen.dart';
import 'package:relapse_flutter/screens/safe_zone/safe_zone_map_screen.dart';
import 'package:relapse_flutter/screens/activity/activity_screen.dart';
import 'package:relapse_flutter/widgets/common/offline_banner.dart';
import 'package:relapse_flutter/widgets/navigation/custom_bottom_navigation_bar.dart';

/// Main shell screen with IndexedStack and bottom navigation.
/// Also handles FCM token registration and notification tap navigation.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Trigger FCM token registration once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmTokenRegistrationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for notification taps and navigate accordingly.
    ref.listen(notificationTapProvider, (_, next) {
      final payload = next.valueOrNull;
      if (payload == null) return;

      switch (payload.screen) {
        case 'activity':
          setState(() => _currentIndex = 3);
          break;
        case 'memory_details':
          if (payload.reminderId != null) {
            Navigator.pushNamed(
              context,
              Routes.memoryDetails,
              arguments: payload.reminderId,
            );
          } else {
            setState(() => _currentIndex = 1);
          }
          break;
        default:
          break;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                HomeScreen(),
                MemoryScreen(),
                SafeZoneMapScreen(),
                ActivityScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
