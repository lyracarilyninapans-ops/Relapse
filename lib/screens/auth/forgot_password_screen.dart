import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_ui_providers.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Forgot Password screen with email form → success view toggle.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(forgotPasswordProvider.notifier).sendResetEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final emailSent = ref.watch(forgotPasswordEmailSentProvider);
    final resetState = ref.watch(forgotPasswordProvider);
    final isLoading = resetState is AsyncLoading;

    // Listen for reset success → toggle to success view
    ref.listen<AsyncValue<void>>(forgotPasswordProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous is AsyncLoading) {
            ref.read(forgotPasswordEmailSentProvider.notifier).state = true;
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_resetErrorMessage(error)),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: emailSent
              ? _buildSuccessView()
              : _buildFormView(isLoading: isLoading),
        ),
      ),
    );
  }

  Widget _buildFormView({required bool isLoading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(
          child:
              Icon(Icons.lock_reset, size: 80, color: AppColors.primaryColor),
        ),
        const SizedBox(height: 24),
        const GradientText(
          'Forgot Password?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Enter your email address and we'll send you a link to reset your password.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black.withAlpha(153),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Email field
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Email Address',
            hintStyle: TextStyle(color: Colors.black.withAlpha(128)),
            prefixIcon:
                const Icon(Icons.email, color: AppColors.primaryColor),
            filled: true,
            fillColor: AppColors.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gradientMiddle,
                width: 2,
              ),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 32),

        GradientButton(
          text: 'SEND RESET LINK',
          isLoading: isLoading,
          onPressed: isLoading ? null : _handleSendReset,
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    final email = _emailController.text.isNotEmpty
        ? _emailController.text
        : 'your@email.com';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(
          child: Icon(
            Icons.mark_email_read,
            size: 100,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        const GradientText(
          'Check Your Email',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "We've sent a password reset link to:",
          style: TextStyle(fontSize: 16, color: Colors.black.withAlpha(153)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          email,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Info box with next steps
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Next Steps:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Check your email inbox\n'
                '2. Click the reset link in the email\n'
                '3. Create a new password\n'
                '4. Sign in with your new password',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[900],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        GradientButton(
          text: 'BACK TO LOGIN',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () {
              ref.read(forgotPasswordEmailSentProvider.notifier).state = false;
            },
            child: const Text("Didn't receive the email? Try again"),
          ),
        ),
      ],
    );
  }

  String _resetErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('user-not-found')) {
      return 'No account found with this email.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to send reset email. Please try again.';
  }
}
