import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_exception.dart';
import '../../data/repositories/auth_repository.dart';

class OtpState {
  final bool isLoading;
  final bool isResending;
  final String? errorMessage;
  final String? successMessage;
  final int resendCountdown;
  final bool canResend;

  const OtpState({
    this.isLoading = false,
    this.isResending = false,
    this.errorMessage,
    this.successMessage,
    this.resendCountdown = 60,
    this.canResend = false,
  });

  OtpState copyWith({
    bool? isLoading,
    bool? isResending,
    String? errorMessage,
    String? successMessage,
    int? resendCountdown,
    bool? canResend,
  }) {
    return OtpState(
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
      errorMessage: errorMessage,
      successMessage: successMessage,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      canResend: canResend ?? this.canResend,
    );
  }
}

class OtpController extends Notifier<OtpState> {
  Timer? _countdownTimer;
  bool _disposed = false;

  @override
  OtpState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _countdownTimer?.cancel();
      _countdownTimer = null;
    });

    // Schedule countdown start after build() completes and state is initialized
    Future.microtask(() {
      if (!_disposed) {
        _startTimer();
      }
    });

    return const OtpState(resendCountdown: 60, canResend: false);
  }

  void _startTimer() {
    _countdownTimer?.cancel();
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

  void restartCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(resendCountdown: 60, canResend: false);
    _startTimer();
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
    String? fcmToken,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.verifyEmail(
        email: email,
        otp: otp,
        fcmToken: fcmToken,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: response.messageToShow,
      );
    } catch (e) {
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to verify OTP. Please try again.';

      state = state.copyWith(isLoading: false, errorMessage: message);
      rethrow;
    }
  }

  Future<void> resendOtp({required String email}) async {
    if (!state.canResend || state.isResending) return;

    state = state.copyWith(isResending: true, errorMessage: null);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final message = await authRepo.resendVerification(email: email);

      state = state.copyWith(
        isResending: false,
        successMessage: message,
      );
      restartCountdown();
    } catch (e) {
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to resend code. Please try again.';

      state = state.copyWith(isResending: false, errorMessage: message);
      rethrow;
    }
  }
}

final otpProvider = NotifierProvider<OtpController, OtpState>(
  OtpController.new,
);
