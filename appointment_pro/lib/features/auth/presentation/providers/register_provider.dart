import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../data/models/register_model.dart';
import '../../data/repositories/auth_repository.dart';

export '../../../../core/services/local_storage_service.dart'
    show localStorageServiceProvider;

class RegisterState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool requiresVerification;
  final String? registeredEmail;

  const RegisterState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.requiresVerification = false,
    this.registeredEmail,
  });
}

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<void> register(RegisterModel model) async {
    state = const RegisterState(isLoading: true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.register(model);

      state = RegisterState(
        requiresVerification: response.requiresVerification,
        registeredEmail: model.email,
        successMessage: response.messageToShow,
      );
    } catch (e) {
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Unable to save your details. Please try again.';

      state = RegisterState(errorMessage: message);
      rethrow;
    }
  }
}

final registerProvider = NotifierProvider<RegisterController, RegisterState>(
  RegisterController.new,
);
