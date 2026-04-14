import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/app_user.dart';
import 'package:relapse_flutter/models/pairing_info.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/notification_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/providers/watch_providers.dart';
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
  String? _lastRegisteredUid;
  ProviderSubscription<AsyncValue<AppUser?>>? _authStateSub;
  final Set<int> _initializedTabs = <int>{0};

  @override
  void initState() {
    super.initState();
    // Trigger FCM token registration once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFcmTokenForCurrentUser();
    });

    _authStateSub = ref.listenManual(authStateProvider, (previous, next) {
      final uid = next.valueOrNull?.uid;
      if (uid == null || uid == _lastRegisteredUid) return;
      _lastRegisteredUid = uid;
      _registerFcmTokenForCurrentUser();
    });
  }

  Future<void> _registerFcmTokenForCurrentUser() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null || uid == _lastRegisteredUid) return;
    _lastRegisteredUid = uid;
    await ref.read(notificationServiceProvider).registerFcmToken(uid);
  }

  @override
  void dispose() {
    _authStateSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    if (!_initializedTabs.contains(currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureTabInitialized(currentIndex);
      });
    }

    // Listen for remote unpair (watch-initiated).
    // When the watch unpairs, Firestore status transitions to 'unpaired'.
    // The pairingInfoProvider stream picks this up and we redirect.
    ref.listen(pairingInfoProvider, (prev, next) {
      final prevInfo = prev?.valueOrNull;
      final nextInfo = next.valueOrNull;
      if (prevInfo != null &&
          prevInfo.status == PairingStatus.paired &&
          nextInfo != null &&
          nextInfo.status == PairingStatus.unpaired) {
        // Skip if the phone itself initiated the unpair.
        if (ref.read(isLocallyUnpairingProvider)) return;
        _handleRemoteUnpair();
      }
    });

    // Listen for notification taps and navigate accordingly.
    ref.listen(notificationTapProvider, (_, next) {
      final payload = next.valueOrNull;
      if (payload == null) return;

      switch (payload.screen) {
        case 'activity':
          _setMainTab(3);
          break;
        case 'memory_details':
          if (payload.reminderId != null) {
            Navigator.pushNamed(
              context,
              Routes.memoryDetails,
              arguments: payload.reminderId,
            );
          } else {
            _setMainTab(1);
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
              children: _buildTabChildren(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _setMainTab,
      ),
    );
  }

  void _setMainTab(int index) {
    _ensureTabInitialized(index);
    ref.read(mainTabIndexProvider.notifier).state = index;
  }

  void _ensureTabInitialized(int index) {
    if (_initializedTabs.contains(index)) return;
    setState(() {
      _initializedTabs.add(index);
    });
  }

  List<Widget> _buildTabChildren() {
    return List<Widget>.generate(4, (index) {
      if (!_initializedTabs.contains(index)) {
        return const SizedBox.shrink();
      }

      return KeyedSubtree(
        key: ValueKey<int>(index),
        child: switch (index) {
          0 => const HomeScreen(),
          1 => const MemoryScreen(),
          2 => const SafeZoneMapScreen(),
          3 => const ActivityScreen(),
          _ => const SizedBox.shrink(),
        },
      );
    });
  }

  /// Called when the watch initiates an unpair and we detect it via Firestore.
  Future<void> _handleRemoteUnpair() async {
    try {
      final authUser = ref.read(authStateProvider).valueOrNull;
      final patient = ref.read(selectedPatientProvider);
      if (authUser != null && patient != null) {
        await ref
            .read(patientRemoteSourceProvider)
            .deletePatient(authUser.uid, patient.id);
      }
    } catch (_) {
      // Best-effort cleanup; navigation still happens.
    }
    if (mounted) {
      await Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.addPatient,
        (route) => false,
      );
    }
  }
}
