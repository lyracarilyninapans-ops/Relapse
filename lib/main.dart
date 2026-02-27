import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'theme/app_theme.dart';
import 'screens/screens.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  final notificationService = FirebaseNotificationService();
  await notificationService.initialize();

  runApp(const ProviderScope(child: RelapseApp()));
}

class RelapseApp extends StatelessWidget {
  const RelapseApp({super.key});

  double _responsiveMaxContentWidth(Size size) {
    final shortestSide = size.shortestSide;
    final isLandscape = size.width > size.height;

    if (shortestSide < 600) return double.infinity;
    if (isLandscape) return 720;
    return 640;
  }

  double _responsiveHorizontalPadding(Size size) {
    final shortestSide = size.shortestSide;
    if (shortestSide < 600) return 0;
    if (shortestSide < 840) return 16;
    return 24;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relapse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        final size = MediaQuery.sizeOf(context);
        final maxWidth = _responsiveMaxContentWidth(size);
        final horizontalPadding = _responsiveHorizontalPadding(size);

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ),
          ),
        );
      },
      initialRoute: Routes.splash,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: const Center(child: Text('Page not found')),
        ),
      ),
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.signup: (_) => const SignUpScreen(),
        Routes.forgotPassword: (_) => const ForgotPasswordScreen(),
        Routes.main: (_) => const MainScreen(),
        Routes.memoryDetails: (_) => const MemoryDetailsScreen(),
        Routes.memoryReminders: (_) => const MemoryReminderListScreen(),
        Routes.createMemory: (_) => const CreateMemoryReminderScreen(),
        Routes.safeZoneConfig: (_) => const SafeZoneConfigScreen(),
        Routes.addPatient: (_) => const AddPatientScreen(),
        Routes.patientSetup: (_) => const PatientSetupScreen(),
        Routes.editPatient: (_) => const EditPatientProfileScreen(),
        Routes.editCaregiver: (_) => const EditCaregiverProfileScreen(),
        Routes.settings: (_) => const SettingsScreen(),
        Routes.offlineMaps: (_) => const OfflineMapsScreen(),
      },
    );
  }
}
