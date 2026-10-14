import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/availability/presentation/screens/availability_screen.dart';
import '../../features/bussiness_setup/presentation/screens/business_list_screen.dart';
import '../../features/bussiness_setup/presentation/screens/business_setup_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/services/presentation/screens/service_form_screen.dart';
import '../../features/services/presentation/screens/services_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/staff/presentation/screens/staff_form_screen.dart';
import '../../features/staff/presentation/screens/staff_screen.dart';
import '../../navigations/main_navigation.dart';

class AppRouter {
  AppRouter._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const businessSetup = '/business-setup';

  // Bottom navigation tab branches
  static const dashboard = '/dashboard';
  static const businessList = '/businesses';
  static const settings = '/settings';
  static const profile = '/profile';

  // Management Module routes
  static const services = '/services';
  static const servicesCreate = '/services/create';
  static const servicesEdit = '/services/:id/edit';
  static const availability = '/availability';
  static const staff = '/staff';
  static const staffCreate = '/staff/create';
  static const staffEdit = '/staff/:id/edit';

  static Page<dynamic> _buildSmoothPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: register,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const RegisterScreen()),
      ),
      GoRoute(
        path: businessSetup,
        pageBuilder: (context, state) {
          final isMandatory = state.uri.queryParameters['mandatory'] == 'true';
          return _buildSmoothPage(
            state: state,
            child: BusinessSetupScreen(isMandatory: isMandatory),
          );
        },
      ),

      // Services Routes
      GoRoute(
        path: services,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const ServicesScreen()),
      ),
      GoRoute(
        path: servicesCreate,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const ServiceFormScreen()),
      ),
      GoRoute(
        path: servicesEdit,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return _buildSmoothPage(
            state: state,
            child: ServiceFormScreen(serviceId: id),
          );
        },
      ),

      // Availability Route
      GoRoute(
        path: availability,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const AvailabilityScreen()),
      ),

      // Staff Routes
      GoRoute(
        path: staff,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const StaffScreen()),
      ),
      GoRoute(
        path: staffCreate,
        pageBuilder: (context, state) =>
            _buildSmoothPage(state: state, child: const StaffFormScreen()),
      ),
      GoRoute(
        path: staffEdit,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'];
          return _buildSmoothPage(
            state: state,
            child: StaffFormScreen(staffId: id),
          );
        },
      ),

      // Bottom Navigation Bar Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: dashboard,
                pageBuilder: (context, state) => _buildSmoothPage(
                  state: state,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: businessList,
                pageBuilder: (context, state) => _buildSmoothPage(
                  state: state,
                  child: const BusinessListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: settings,
                pageBuilder: (context, state) => _buildSmoothPage(
                  state: state,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: profile,
                pageBuilder: (context, state) => _buildSmoothPage(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
