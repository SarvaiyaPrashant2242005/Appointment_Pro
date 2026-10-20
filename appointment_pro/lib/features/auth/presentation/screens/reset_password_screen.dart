import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/forgot_password_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  static const int _otpLength = 6;
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _otpControllers = [];
  final List<FocusNode> _focusNodes = [];

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _otpLength; i++) {
      _otpControllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _currentOtp => _otpControllers.map((c) => c.text.trim()).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handles clipboard paste of whole code
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
      }
      final nextIndex =
          digits.length < _otpLength ? digits.length : _otpLength - 1;
      _focusNodes[nextIndex].requestFocus();
      return;
    }

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
    }
  }

  Future<void> _handleReset() async {
    setState(() => _submitted = true);

    final otp = _currentOtp;
    if (otp.length != _otpLength) {
      AppToast.warning(
        context,
        'Please enter all 6 digits of the verification code.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(forgotPasswordProvider.notifier);

    try {
      final successMsg = await controller.resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      AppToast.success(context, successMsg);
      context.go(AppRouter.login);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.messageToShow
          : e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to reset password. Please try again.';
      AppToast.error(context, message);
    }
  }

  Future<void> _handleResend() async {
    final state = ref.read(forgotPasswordProvider);
    if (!state.canResend || state.isResending) return;

    final controller = ref.read(forgotPasswordProvider.notifier);

    try {
      final successMsg =
          await controller.resendResetCode(email: widget.email);
      if (!mounted) return;
      AppToast.success(
        context,
        successMsg.isNotEmpty ? successMsg : 'Verification code resent successfully.',
      );
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
    final state = ref.watch(forgotPasswordProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;

    final double titleFontSize = isKeyboardOpen
        ? 19.0
        : (screenHeight > 750 ? 24.0 : 20.0);

    final int topFlex = isKeyboardOpen ? 3 : 5;
    final int bottomFlex = isKeyboardOpen ? 12 : 11;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: Column(
              children: [
                // Header Area
                Expanded(
                  flex: topFlex,
                  child: Center(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: isKeyboardOpen ? 2 : 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.key_rounded,
                                size: 28,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Reset Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter the 6-digit code sent to\n${widget.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Form Sheet
                Expanded(
                  flex: bottomFlex,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          isKeyboardOpen ? 16 : 24,
                          24,
                          24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 6-digit OTP Row
                                  Text(
                                    'Verification Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(_otpLength, (index) {
                                      return SizedBox(
                                        width: (screenWidth - 48 - (_otpLength - 1) * 8) / _otpLength > 52
                                            ? 52
                                            : ((screenWidth - 48 - (_otpLength - 1) * 8) / _otpLength).clamp(40, 52),
                                        height: 52,
                                        child: KeyboardListener(
                                          focusNode: FocusNode(),
                                          onKeyEvent: (event) =>
                                              _onKeyEvent(index, event),
                                          child: TextFormField(
                                            controller: _otpControllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            maxLength: 1,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              filled: true,
                                              fillColor: isDark
                                                  ? AppColors.darkInputFill
                                                  : AppColors.inputFill,
                                              contentPadding: EdgeInsets.zero,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.border,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.border,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppColors.accent,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            onChanged: (val) =>
                                                _onDigitChanged(index, val),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 10),

                                  // Resend timer row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (state.isResending) ...[
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Sending code...',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ] else if (!state.canResend) ...[
                                        Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Resend code in ${state.resendCountdown}s',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ] else ...[
                                        TextButton(
                                          onPressed: _handleResend,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Resend Code',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // New Password Field
                                  AppTextField(
                                    label: 'New Password',
                                    isRequired: true,
                                    hint: 'At least 6 characters',
                                    controller: _passwordController,
                                    obscureText: true,
                                    textInputAction: TextInputAction.next,
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'New password is required';
                                      }
                                      if (v.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),

                                  // Confirm New Password Field
                                  AppTextField(
                                    label: 'Confirm New Password',
                                    isRequired: true,
                                    hint: 'Re-enter your new password',
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleReset(),
                                    prefixIcon:
                                        const Icon(Icons.lock_reset_rounded),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Please confirm your new password';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 26),

                                  // Submit Button
                                  AppButton(
                                    label: 'Reset Password',
                                    icon: Icons.check_circle_outline_rounded,
                                    onPressed: _handleReset,
                                    isLoading: state.isLoading,
                                  ),
                                  const SizedBox(height: 16),

                                  Center(
                                    child: TextButton(
                                      onPressed: () => context.go(AppRouter.login),
                                      child: const Text(
                                        'Cancel and return to Sign In',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
