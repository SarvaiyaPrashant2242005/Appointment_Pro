import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum ConfirmDialogType { logout, delete, exit, custom }

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? confirmButtonColor;
  final bool isDestructive;
  final ConfirmDialogType type;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.icon = Icons.help_outline_rounded,
    this.iconColor,
    this.iconBackgroundColor,
    this.confirmButtonColor,
    this.isDestructive = false,
    this.type = ConfirmDialogType.custom,
  });

  /// Factory dialog for Logout Confirmation
  static Future<bool> showLogout(
    BuildContext context, {
    String title = 'Log Out',
    String message = 'Are you sure you want to log out of your account?',
    String confirmText = 'Log Out',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppConfirmDialog(
        type: ConfirmDialogType.logout,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: Icons.logout_rounded,
        iconColor: AppColors.error,
        iconBackgroundColor: AppColors.error.withValues(alpha: 0.12),
        confirmButtonColor: AppColors.error,
        isDestructive: true,
      ),
    );
    return result ?? false;
  }

  /// Factory dialog for Delete Confirmation
  static Future<bool> showDelete(
    BuildContext context, {
    String? title,
    String? message,
    String? itemName,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) async {
    final resolvedTitle =
        title ??
        (itemName != null ? 'Delete $itemName?' : 'Delete Confirmation');
    final resolvedMessage =
        message ??
        'Are you sure you want to delete this? This action cannot be undone.';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppConfirmDialog(
        type: ConfirmDialogType.delete,
        title: resolvedTitle,
        message: resolvedMessage,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: Icons.delete_outline_rounded,
        iconColor: AppColors.error,
        iconBackgroundColor: AppColors.error.withValues(alpha: 0.12),
        confirmButtonColor: AppColors.error,
        isDestructive: true,
      ),
    );
    return result ?? false;
  }

  /// Factory dialog for App Exit Confirmation
  static Future<bool> showExit(
    BuildContext context, {
    String title = 'Exit App',
    String message = 'Are you sure you want to exit AppointmentPro?',
    String confirmText = 'Exit',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppConfirmDialog(
        type: ConfirmDialogType.exit,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: Icons.exit_to_app_rounded,
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
        confirmButtonColor: AppColors.primary,
        isDestructive: false,
      ),
    );
    return result ?? false;
  }

  /// Generic customizable confirmation dialog
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData icon = Icons.info_outline_rounded,
    Color? iconColor,
    Color? iconBackgroundColor,
    Color? confirmButtonColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        confirmButtonColor: confirmButtonColor,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedIconColor =
        iconColor ??
        (isDestructive ? AppColors.error : theme.colorScheme.primary);
    final resolvedIconBg =
        iconBackgroundColor ?? resolvedIconColor.withValues(alpha: 0.12);
    final resolvedBtnColor =
        confirmButtonColor ??
        (isDestructive ? AppColors.error : theme.colorScheme.primary);

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular Icon Badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: resolvedIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: resolvedIconColor),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          foregroundColor: isDark
                              ? Colors.white
                              : const Color(0xFF334155),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm Button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: resolvedBtnColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
