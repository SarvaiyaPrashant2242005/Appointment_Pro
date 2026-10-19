import 'package:appointment_pro/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VerifyOtpScreen renders without ProviderException', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: VerifyOtpScreen(email: 'test@example.com'),
        ),
      ),
    );

    // Initial build should render smoothly with no ProviderException
    expect(find.text('Verify Email Code'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Verify & Continue'), findsOneWidget);
  });
}
