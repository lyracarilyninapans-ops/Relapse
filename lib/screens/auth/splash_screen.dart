import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/app_user.dart';
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
  ProviderSubscription<AsyncValue<AppUser?>>? _authWaitSubscription;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (_didNavigate) return;

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) {
        unawaited(_navigateForUser(user));
      },
      loading: () {
        // Still loading — listen for the first emission
        _waitForAuth();
      },
      error: (error, stackTrace) {
        unawaited(_navigateForUser(null));
      },
    );
  }

  void _waitForAuth() {
    _authWaitSubscription?.close();
    _authWaitSubscription = ref.listenManual(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          unawaited(_navigateForUser(user));
        },
        loading: () {},
        error: (error, stackTrace) {
          unawaited(_navigateForUser(null));
        },
      );
    });
  }

  Future<void> _navigateForUser(AppUser? user) async {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    _authWaitSubscription?.close();

    final route = user != null ? Routes.main : Routes.login;
    await Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _authWaitSubscription?.close();
    super.dispose();
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
                  errorBuilder: (context, error, stackTrace) => Container(
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
