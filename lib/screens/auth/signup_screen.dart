import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/providers/auth_ui_providers.dart';
import 'package:relapse_flutter/theme/app_colors.dart';
import 'package:relapse_flutter/theme/app_gradients.dart';
import 'package:relapse_flutter/widgets/common/common.dart';

/// Sign Up screen with name, email, password, confirm, terms checkbox.
class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  static double _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength;
  }

  static String _strengthLabel(double strength) {
    switch (strength.toInt()) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      case 4:
        return 'Very Strong';
      default:
        return '';
    }
  }

  static Color _strengthColor(double strength) {
    switch (strength.toInt()) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.black.withAlpha(128)),
      prefixIcon: Icon(prefixIcon, color: AppColors.primaryColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.gradientMiddle,
          width: 2,
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'These are the Terms of Service for the Relapse Memory Care '
            'Support application.\n\n'
            'By using this app, you agree to these terms.\n\n'
            '1. The app is intended for memory care support only.\n'
            '2. You are responsible for accurate patient information.\n'
            '3. Location data is used solely for safe zone monitoring.\n'
            '4. We respect your privacy and handle data securely.\n\n'
            'For full terms, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy for Relapse Memory Care Support\n\n'
            '• We collect only necessary data for app functionality.\n'
            '• Patient location data is encrypted and stored securely.\n'
            '• Your data is never sold to third parties.\n'
            '• You can request data deletion at any time.\n'
            '• We use industry-standard security measures.\n\n'
            'For more details, visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obscurePassword = ref.watch(signUpObscurePasswordProvider);
    final obscureConfirm = ref.watch(signUpObscureConfirmProvider);
    final agreedToTerms = ref.watch(signUpAgreedToTermsProvider);
    final password = ref.watch(signUpPasswordProvider);
    final passwordStrength = _passwordStrength(password);
    final strengthLabel = _strengthLabel(passwordStrength);
    final strengthColor = _strengthColor(passwordStrength);
    const isLoading = false;

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
          child: Column(
            children: [
              // Logo with gradient shader
              ShaderMask(
                shaderCallback: (bounds) => AppGradients.iconText.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                blendMode: BlendMode.srcIn,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  color: Colors.white,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.favorite,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const GradientText(
                'Create Your Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Join us to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black.withAlpha(153),
                ),
              ),
              const SizedBox(height: 32),

              // Form
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    TextFormField(
                      decoration: _inputDecoration(
                        hint: 'Full Name',
                        prefixIcon: Icons.person,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      decoration: _inputDecoration(
                        hint: 'Email Address',
                        prefixIcon: Icons.email,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      obscureText: obscurePassword,
                      onChanged: (value) {
                        ref.read(signUpPasswordProvider.notifier).state = value;
                      },
                      decoration: _inputDecoration(
                        hint: 'Password',
                        prefixIcon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            ref
                                .read(signUpObscurePasswordProvider.notifier)
                                .state = !obscurePassword;
                          },
                        ),
                      ),
                    ),

                    // Password strength indicator
                    if (password.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: passwordStrength / 4,
                        minHeight: 4,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(strengthColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strengthLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: strengthColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use 8+ characters with uppercase, lowercase, number & symbol',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withAlpha(128),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      obscureText: obscureConfirm,
                      decoration: _inputDecoration(
                        hint: 'Confirm Password',
                        prefixIcon: Icons.lock,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            ref
                                .read(signUpObscureConfirmProvider.notifier)
                                .state = !obscureConfirm;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Terms checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    activeColor: AppColors.primaryColor,
                    onChanged: (val) {
                      ref.read(signUpAgreedToTermsProvider.notifier).state =
                          val ?? false;
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        children: [
                          const Text('I agree to the '),
                          GestureDetector(
                            onTap: () => _showTermsDialog(context),
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(' and '),
                          GestureDetector(
                            onTap: () => _showPrivacyDialog(context),
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sign Up button
              GradientButton(
                text: 'SIGN UP',
                isLoading: isLoading,
                onPressed: () {
                  // Placeholder: show success and navigate to login
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Account Created!'),
                      content: const Text(
                        'Your account has been created successfully.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // close dialog
                            Navigator.pop(context); // back to login
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Login'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
