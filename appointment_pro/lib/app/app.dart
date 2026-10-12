import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class AppointmentProApp extends StatelessWidget {
  const AppointmentProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'AppointmentPro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
