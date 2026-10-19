import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import '../core/services/fcm_service.dart';
import '../core/services/local_notification_service.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/bookings/presentation/providers/booking_provider.dart';
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

class _AppointmentProAppState extends ConsumerState<AppointmentProApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _tapSub;
  StreamSubscription<dynamic>? _msgSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFcmListeners();
    _setupLocalNotificationTap();
    _registerFcmTokenWithServer();
  }

  void _setupLocalNotificationTap() {
    LocalNotificationService.instance.setOnTapCallback((payload) {
      if (payload != null && payload.isNotEmpty) {
        if (payload.startsWith('/')) {
          AppRouter.router.push(payload);
        } else {
          AppRouter.navigateToBooking(payload);
        }
      } else {
        AppRouter.navigateToNotifications();
      }
    });
  }

  void _setupFcmListeners() {
    _tapSub = FcmService.instance.onBookingTap.listen((bookingId) {
      if (bookingId.isNotEmpty) {
        AppRouter.navigateToBooking(bookingId);
      }
    });

    _msgSub = FcmService.instance.messageStream.listen((_) {
      ref.read(notificationsProvider.notifier).refresh();
      ref.read(bookingsProvider.notifier).refresh();
    });

    FcmService.instance.onTokenRefreshCallback = (newToken) {
      _saveTokenToServer(newToken);
    };
  }

  void _registerFcmTokenWithServer() {
    final token = FcmService.instance.fcmToken;
    if (token != null && token.isNotEmpty) {
      _saveTokenToServer(token);
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    try {
      await ref.read(authRepositoryProvider).saveFcmToken(token);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh live bookings, notifications, and device token when returning to foreground
      ref.read(bookingsProvider.notifier).refresh();
      ref.read(notificationsProvider.notifier).refresh();
      _registerFcmTokenWithServer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Keep live booking sync active throughout the application
    ref.watch(bookingWebSocketSyncProvider);

    // Reactively subscribe device to active business FCM topic
    ref.listen<String?>(activeBusinessIdProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        FcmService.instance.subscribeToBusiness(next);
        _registerFcmTokenWithServer();
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
