import 'package:appointment_pro/features/auth/presentation/providers/otp_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OtpController initializes without uninitialized state error', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Reading the provider should initialize smoothly with 60s countdown
    final state = container.read(otpProvider);
    expect(state.resendCountdown, 60);
    expect(state.canResend, false);
    expect(state.isLoading, false);
  });
}
