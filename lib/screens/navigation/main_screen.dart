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

/// Provider to allow child screens to switch the main tab index.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

/// Main shell screen with IndexedStack and bottom navigation.
/// Also handles FCM token registration and notification tap navigation.
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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
    final currentIndex = ref.watch(mainTabIndexProvider);

    // Listen for notification taps and navigate accordingly.
    ref.listen(notificationTapProvider, (_, next) {
      final payload = next.valueOrNull;
      if (payload == null) return;

      switch (payload.screen) {
        case 'activity':
          ref.read(mainTabIndexProvider.notifier).state = 3;
          break;
        case 'memory_details':
          if (payload.reminderId != null) {
            Navigator.pushNamed(
              context,
              Routes.memoryDetails,
              arguments: payload.reminderId,
            );
          } else {
            ref.read(mainTabIndexProvider.notifier).state = 1;
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
              index: currentIndex,
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
        currentIndex: currentIndex,
        onTap: (index) => ref.read(mainTabIndexProvider.notifier).state = index,
      ),
    );
  }
}
