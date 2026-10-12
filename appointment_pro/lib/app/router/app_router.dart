import '../../features/auth/presentation/screens/login_screen.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static const splash = '/';
  static const register = '/register';
  static const login = '/login';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
    ],
  );
}
