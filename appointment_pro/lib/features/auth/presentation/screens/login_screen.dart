import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/login_provider.dart';
import '../widgets/login_form.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (ref.read(loginProvider).isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref
          .read(loginProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      AppToast.success(context, 'Signed in successfully!');
      context.go(AppRouter.dashboard);
    } catch (e) {
      if (!mounted) return;

      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Unable to sign in. Please try again.';

      AppToast.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth > 600;

    // Responsive dimensions based on device size & keyboard state
    final double logoSize = isKeyboardOpen
        ? 52.0
        : (screenHeight > 820
            ? 130.0
            : (screenHeight > 700 ? 100.0 : 72.0));

    final double titleFontSize = isKeyboardOpen
        ? 20.0
        : (screenHeight > 750 ? 28.0 : 22.0);

    final double subtitleFontSize = isKeyboardOpen ? 12.0 : 14.0;
    final double topVerticalPadding = isKeyboardOpen ? 8.0 : (screenHeight > 750 ? 16.0 : 8.0);
    final int topFlex = isKeyboardOpen ? 4 : 9;
    final int bottomFlex = isKeyboardOpen ? 12 : 9;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await AppConfirmDialog.showExit(context);
        if (confirmed) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : double.infinity,
              ),
              child: Column(
                children: [
                  // Top Branding Area (dynamically scales for screen height & keyboard)
                  Expanded(
                    flex: topFlex,
                    child: Center(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: topVerticalPadding,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Logo
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    logoSize > 80 ? 20 : 14,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    logoSize > 80 ? 20 : 14,
                                  ),
                                  child: Image.asset(
                                    AppAssets.appIconDark,
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(height: isKeyboardOpen ? 10 : 16),
                              Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'sans-serif',
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (!isKeyboardOpen) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to manage your appointments\nand track your schedule.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'sans-serif',
                                    fontSize: subtitleFontSize,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Curved Bottom Sheet (responsive, smooth scroll, fits all forms)
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
                            isKeyboardOpen ? 18 : 26,
                            24,
                            24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: LoginForm(
                                formKey: _formKey,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                isLoading: loginState.isLoading,
                                onSubmit: _login,
                                onRegisterTap: () =>
                                    context.go(AppRouter.register),
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
      ),
    );
  }
}
