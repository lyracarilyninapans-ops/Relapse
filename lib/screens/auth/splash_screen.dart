import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/routes.dart';
import 'package:relapse_flutter/theme/app_colors.dart';

/// Splash screen with gradient background, logo, app name, and spinner.
/// Checks auth state and routes accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        if (!mounted) return;
        if (user != null) {
          Navigator.pushReplacementNamed(context, Routes.main);
        } else {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      },
      loading: () {
        // Still loading — listen for the first emission
        _waitForAuth();
      },
      error: (_, __) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.login);
      },
    );
  }

  void _waitForAuth() {
    ref.listenManual(authStateProvider, (previous, next) {
      if (!mounted) return;
      next.whenData((user) {
        if (!mounted) return;
        if (user != null) {
          Navigator.pushReplacementNamed(context, Routes.main);
        } else {
          Navigator.pushReplacementNamed(context, Routes.login);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMiddle,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: AppColors.gradientMiddle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Relapse',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Memory Care Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withAlpha(179),
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.tertiaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
