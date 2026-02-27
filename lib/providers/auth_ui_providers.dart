import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginObscurePasswordProvider =
    StateProvider.autoDispose<bool>((ref) => true);

final signUpObscurePasswordProvider =
    StateProvider.autoDispose<bool>((ref) => true);

final signUpObscureConfirmProvider =
    StateProvider.autoDispose<bool>((ref) => true);

final signUpAgreedToTermsProvider =
    StateProvider.autoDispose<bool>((ref) => false);

final signUpPasswordProvider =
    StateProvider.autoDispose<String>((ref) => '');

final forgotPasswordEmailSentProvider =
    StateProvider.autoDispose<bool>((ref) => false);
