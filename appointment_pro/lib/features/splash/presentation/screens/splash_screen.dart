import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/register_provider.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isChecking = true;
  bool _hasNoInternet = false;

  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    setState(() {
      _isChecking = true;
      _hasNoInternet = false;
    });

    // Brief splash brand delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Verify internet connectivity on startup
    final isConnected =
        await ref.read(networkServiceProvider).hasInternetConnection();
    if (!mounted) return;

    if (!isConnected) {
      setState(() {
        _isChecking = false;
        _hasNoInternet = true;
      });

      AppToast.warning(
        context,
        'No connection, please connect to the internet',
      );
      return;
    }

    // Connection verified, proceed with loading auth and profile
    ref.read(splashProvider.notifier).finishLoading();

    try {
      final storage = ref.read(localStorageServiceProvider);
      final isLoggedIn = await storage.isLoggedIn();
      if (!mounted) return;

      if (isLoggedIn) {
        List<BusinessModel> businesses = [];
        try {
          businesses =
              await ref.read(businessProvider.notifier).fetchFresh();
        } catch (_) {
          businesses = ref.read(businessProvider).value ?? [];
        }
        if (!mounted) return;

        if (businesses.isEmpty) {
          context.go('${AppRouter.businessSetup}?mandatory=true');
        } else {
          context.go(AppRouter.dashboard);
        }
      } else {
        context.go(AppRouter.login);
      }
    } catch (_) {
      if (!mounted) return;
      // Double check if failure was due to network drop
      final stillOnline =
          await ref.read(networkServiceProvider).hasInternetConnection();
      if (!mounted) return;

      if (!stillOnline) {
        setState(() {
          _isChecking = false;
          _hasNoInternet = true;
        });
        AppToast.error(
          context,
          'No connection, please connect to the internet',
        );
      } else {
        context.go(AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Image(image: AssetImage(AppAssets.appIconDark)),
                ),
                const SizedBox(height: 22),
                const Text(
                  'AppointmentPro',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Booking & Business Manager',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),
                if (_hasNoInternet) ...[
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 28,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No connection, please connect to the internet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _isChecking ? null : _checkAndNavigate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            icon: _isChecking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20),
                            label: Text(
                              _isChecking ? 'Checking...' : 'Retry Connection',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const AppLoader(
                    size: 26,
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
