import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/main': (_) => const MainScreen(),
        '/memory-details': (_) => const MemoryDetailsScreen(),
        '/memory-reminders': (_) => const MemoryReminderListScreen(),
        '/create-memory': (_) => const CreateMemoryReminderScreen(),
        '/safe-zone-config': (_) => const SafeZoneConfigScreen(),
        '/add-patient': (_) => const AddPatientScreen(),
        '/patient-setup': (_) => const PatientSetupScreen(),
        '/edit-patient': (_) => const EditPatientProfileScreen(),
        '/edit-caregiver': (_) => const EditCaregiverProfileScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/offline-maps': (_) => const OfflineMapsScreen(),
      },
    );
  }
}
