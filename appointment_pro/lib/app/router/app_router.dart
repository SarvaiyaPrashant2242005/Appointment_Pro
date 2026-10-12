import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      // GoRoute(
      //   path: login,
      //   builder: (context, state) => const LoginScreen(),
      // ),
      // GoRoute(
      //   path: dashboard,
      //   builder: (context, state) => const DashboardScreen(),
      // ),
    ],
  );
}
