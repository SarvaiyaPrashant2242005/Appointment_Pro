import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/repositories/auth_repository.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool requiresVerification;
  final String? unverifiedEmail;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.requiresVerification = false,
    this.unverifiedEmail,
  });
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<String> login({
    required String email,
    required String password,
    String? fcmToken,
  }) async {
    state = const LoginState(isLoading: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.login(
        email: email,
        password: password,
        fcmToken: fcmToken,
      );
      final messageToShow = response.messageToShow;
      state = LoginState(successMessage: messageToShow);
      return messageToShow;
    } catch (e) {
      final isVerificationRequired = (e is ApiException && e.requiresVerification) ||
          (e is ApiException &&
              (e.messageToShow.toLowerCase().contains('not verified') ||
                  e.message.toLowerCase().contains('not verified')));

      if (isVerificationRequired) {
        state = LoginState(
          errorMessage: e is ApiException ? e.messageToShow : null,
          requiresVerification: true,
          unverifiedEmail: (e is ApiException ? e.email : null) ?? email,
        );
        rethrow;
      }

      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Unable to sign in. Please try again.';

      state = LoginState(errorMessage: message);
      rethrow;
    }
  }
}

final loginProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);
