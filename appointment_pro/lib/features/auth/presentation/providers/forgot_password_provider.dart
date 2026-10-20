import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordState {
  final bool isLoading;
  final bool isResending;
  final String? errorMessage;
  final String? successMessage;
  final int resendCountdown;
  final bool canResend;

  const ForgotPasswordState({
    this.isLoading = false,
    this.isResending = false,
    this.errorMessage,
    this.successMessage,
    this.resendCountdown = 60,
    this.canResend = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    bool? isResending,
    String? errorMessage,
    String? successMessage,
    int? resendCountdown,
    bool? canResend,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
      errorMessage: errorMessage,
      successMessage: successMessage,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      canResend: canResend ?? this.canResend,
    );
  }
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  Timer? _countdownTimer;
  bool _disposed = false;

  @override
  ForgotPasswordState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _countdownTimer?.cancel();
      _countdownTimer = null;
    });

    return const ForgotPasswordState();
  }

  void startResendTimer() {
    _countdownTimer?.cancel();
    state = state.copyWith(resendCountdown: 60, canResend: false);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (state.resendCountdown <= 1) {
        timer.cancel();
        state = state.copyWith(resendCountdown: 0, canResend: true);
      } else {
        state = state.copyWith(resendCountdown: state.resendCountdown - 1);
      }
    });
  }

  /// Sends a 6-digit password reset code to the provided email
  Future<String> sendResetCode({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final message = await authRepo.forgotPassword(email: email);
      state = state.copyWith(
        isLoading: false,
        successMessage: message,
      );
      startResendTimer();
      return message;
    } catch (e) {
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to send reset code. Please try again.';

      state = state.copyWith(isLoading: false, errorMessage: message);
      rethrow;
    }
  }

  /// Resends the password reset code
  Future<String> resendResetCode({required String email}) async {
    if (!state.canResend || state.isResending) return '';

    state = state.copyWith(isResending: true, errorMessage: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final message = await authRepo.forgotPassword(email: email);
      state = state.copyWith(
        isResending: false,
        successMessage: message,
      );
      startResendTimer();
      return message;
    } catch (e) {
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to resend reset code. Please try again.';

      state = state.copyWith(isResending: false, errorMessage: message);
      rethrow;
    }
  }

  /// Verifies OTP and resets the password
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final message = await authRepo.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: message,
      );
      return message;
    } catch (e) {
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to reset password. Please try again.';

      state = state.copyWith(isLoading: false, errorMessage: message);
      rethrow;
    }
  }
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordController, ForgotPasswordState>(
  ForgotPasswordController.new,
);
