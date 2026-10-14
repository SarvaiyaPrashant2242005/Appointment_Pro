import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../core/services/fcm_service.dart';
import '../features/bussiness_setup/presentation/providers/business_provider.dart';
import '../features/notifications/presentation/providers/notification_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

class AppointmentProApp extends ConsumerStatefulWidget {
  const AppointmentProApp({super.key});

  @override
  ConsumerState<AppointmentProApp> createState() => _AppointmentProAppState();
}

class _AppointmentProAppState extends ConsumerState<AppointmentProApp> {
  StreamSubscription<String>? _tapSub;
  StreamSubscription<dynamic>? _msgSub;

  @override
  void initState() {
    super.initState();
    _setupFcmListeners();
  }

  void _setupFcmListeners() {
    _tapSub = FcmService.instance.onBookingTap.listen((bookingId) {
      if (bookingId.isNotEmpty) {
        AppRouter.router.push('/bookings/$bookingId');
      }
    });

    _msgSub = FcmService.instance.messageStream.listen((_) {
      ref.read(notificationsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Reactively subscribe device to active business FCM topic
    ref.listen<String?>(activeBusinessIdProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        FcmService.instance.subscribeToBusiness(next);
      }
    });

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'AppointmentPro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
