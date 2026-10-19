import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme/theme_provider.dart';
import 'core/services/fcm_service.dart';
import 'core/services/local_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }

  try {
    await LocalNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Local notifications initialization note: $e');
  }

  try {
    await FcmService.instance.initialize();
  } catch (e) {
    debugPrint('FCM initialization note: $e');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AppointmentProApp(),
    ),
  );
}
