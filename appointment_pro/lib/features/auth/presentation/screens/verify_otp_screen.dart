import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../providers/otp_provider.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _otpLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handles clipboard paste of whole code
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextIndex = digits.length < _otpLength ? digits.length : _otpLength - 1;
      _focusNodes[nextIndex].requestFocus();
      if (_currentOtp.length == _otpLength) {
        _verifyCode();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == _otpLength) {
          _verifyCode();
        }
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  Future<void> _verifyCode() async {
    final otp = _currentOtp;
    if (otp.length != _otpLength) {
      AppToast.warning(context, 'Please enter all 6 digits of the code.');
      return;
    }

    if (ref.read(otpProvider).isLoading) return;

    try {
      await ref.read(otpProvider.notifier).verifyOtp(
            email: widget.email,
            otp: otp,
          );

      if (!mounted) return;

      final successMessage = ref.read(otpProvider).successMessage ??
          'Email verified successfully! Welcome to AppointmentPro.';
      AppToast.success(context, successMessage);

      // Check whether user has existing businesses or needs setup
      final businesses =
          await ref.read(businessRepositoryProvider).getBusinesses();

      if (!mounted) return;

      if (businesses.isEmpty) {
        context.go('${AppRouter.businessSetup}?mandatory=true');
      } else {
        context.go(AppRouter.dashboard);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to verify code. Please try again.';
      AppToast.error(context, message);
    }
  }

  Future<void> _resendCode() async {
    final otpState = ref.read(otpProvider);
    if (!otpState.canResend || otpState.isResending) return;

    try {
      await ref.read(otpProvider.notifier).resendOtp(email: widget.email);
      if (!mounted) return;
      final successMessage = ref.read(otpProvider).successMessage ??
          'A fresh 6-digit verification code has been sent!';
      AppToast.info(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to resend code. Please try again.';
      AppToast.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 480 : double.infinity,
            ),
            child: Column(
              children: [
                // Top Header section
                Padding(
                  padding: isKeyboardOpen
                      ? const EdgeInsets.fromLTRB(20, 10, 20, 12)
                      : const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRouter.login);
                              }
                            },
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            tooltip: 'Back',
                          ),
                          Container(
                            width: isKeyboardOpen ? 40 : 48,
                            height: isKeyboardOpen ? 40 : 48,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Image(
                              image: AssetImage(AppAssets.appIconDark),
                            ),
                          ),
                          const SizedBox(width: 48), // balance back button
                        ],
                      ),
                      SizedBox(height: isKeyboardOpen ? 8 : 16),
                      Text(
                        'Verify Email Code',
                        style: TextStyle(
                          fontSize: isKeyboardOpen ? 20 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a 6-digit confirmation code to:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Main Card Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Enter 6-Digit Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Type the numeric digits sent to your inbox',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // 6 OTP Digit Input Boxes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_otpLength, (index) {
                              final boxWidth = isTablet
                                  ? 56.0
                                  : ((screenWidth - 48 - 40) / _otpLength).clamp(42.0, 52.0);

                              return SizedBox(
                                width: boxWidth,
                                height: 58,
                                child: KeyboardListener(
                                  focusNode: FocusNode(),
                                  onKeyEvent: (event) => _onKeyEvent(index, event),
                                  child: TextFormField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(6),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (val) => _onDigitChanged(index, val),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor: isDark
                                          ? AppColors.darkInputFill
                                          : AppColors.inputFill,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.accent,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 32),

                          // Verify Button
                          AppButton(
                            label: 'Verify & Continue',
                            isLoading: otpState.isLoading,
                            onPressed: _verifyCode,
                          ),

                          const SizedBox(height: 24),

                          // Resend Code Timer / Button
                          Center(
                            child: otpState.canResend
                                ? TextButton.icon(
                                    onPressed: otpState.isResending ? null : _resendCode,
                                    icon: otpState.isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                            color: AppColors.accent,
                                          ),
                                    label: const Text(
                                      'Resend Code',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Resend code in ${otpState.resendCountdown}s',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 16),

                          // Back to login/register option
                          Center(
                            child: TextButton(
                              onPressed: () => context.go(AppRouter.login),
                              child: Text(
                                'Wrong email? Back to Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
