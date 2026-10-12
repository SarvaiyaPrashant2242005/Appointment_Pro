import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AppToast {
  AppToast._();

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.success,
      icon: Icons.check_circle_outline,
      color: const Color(0xFF16A34A),
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.error,
      icon: Icons.error_outline,
      color: const Color(0xFFDC2626),
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.warning,
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFF59E0B),
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.info,
      icon: Icons.info_outline,
      color: const Color(0xFF0891B2),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required ToastificationType type,
    required IconData icon,
    required Color color,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      title: Text(message),
      icon: Icon(icon, color: color),
      primaryColor: color,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 250),
      borderRadius: BorderRadius.circular(12),
      closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
      showProgressBar: false,
    );
  }
}
