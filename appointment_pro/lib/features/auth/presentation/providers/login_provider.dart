import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'register_provider.dart';

class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({this.isLoading = false, this.errorMessage});
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const LoginState(isLoading: true);

    try {
      final storage = ref.read(localStorageServiceProvider);
      await storage.login(email: email, password: password);
      state = const LoginState();
    } catch (e) {
      final message = e is Exception
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
