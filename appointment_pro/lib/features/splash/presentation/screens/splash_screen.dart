import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToRegister();
  }

  Future<void> _navigateToRegister() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ref.read(splashProvider.notifier).finishLoading();
    context.go(AppRouter.register);
  }

  @override
  Widget build(BuildContext context) {
    final splashState = ref.watch(splashProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Image(image: AssetImage(AppAssets.appIconDark)),
              ),
              const SizedBox(height: 24),
              const Text(
                'AppointmentPro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Booking & Business Manager',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              if (splashState.isLoading)
                const AppLoader(
                  size: 24,
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
