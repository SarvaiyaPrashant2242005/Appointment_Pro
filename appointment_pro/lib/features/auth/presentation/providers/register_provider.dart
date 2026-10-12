import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../data/models/register_model.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class RegisterState {
  final bool isLoading;
  final String? errorMessage;

  const RegisterState({this.isLoading = false, this.errorMessage});
}

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<void> register(RegisterModel model) async {
    state = const RegisterState(isLoading: true);

    try {
      final storage = ref.read(localStorageServiceProvider);

      final isAlreadyRegistered = await storage.isEmailRegistered(model.email);
      if (isAlreadyRegistered) {
        throw Exception('An account with this email is already registered.');
      }

      await storage.saveUserProfile(jsonEncode(model.toJson()));

      state = const RegisterState();
    } catch (e) {
      final message = e is Exception
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
