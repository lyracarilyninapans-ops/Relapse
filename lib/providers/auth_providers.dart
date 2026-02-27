import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/app_user.dart';
import 'package:relapse_flutter/services/auth_service.dart';

/// Provides the singleton [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});

/// Stream of the current authenticated user (null when signed out).
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

/// Notifier that manages sign-in state and calls.
class SignInNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  SignInNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signInWithEmail(email, password),
    );
  }
}

final signInProvider =
    StateNotifierProvider.autoDispose<SignInNotifier, AsyncValue<void>>((ref) {
  return SignInNotifier(ref.watch(authServiceProvider));
});

/// Notifier that manages sign-up state and calls.
class SignUpNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  SignUpNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signUp(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signUpWithEmail(email, password, displayName),
    );
  }
}

final signUpProvider =
    StateNotifierProvider.autoDispose<SignUpNotifier, AsyncValue<void>>((ref) {
  return SignUpNotifier(ref.watch(authServiceProvider));
});

/// Notifier that manages password reset state.
class ForgotPasswordNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  ForgotPasswordNotifier(this._authService)
      : super(const AsyncValue.data(null));

  Future<void> sendResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.sendPasswordResetEmail(email),
    );
  }
}

final forgotPasswordProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordNotifier, AsyncValue<void>>((ref) {
  return ForgotPasswordNotifier(ref.watch(authServiceProvider));
});
