import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/app_notification_model.dart';

class NotificationItemTile extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final VoidCallback? onMarkRead;

  const NotificationItemTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismissed,
    this.onMarkRead,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.newBooking:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.bookingCancelled:
        return const Color(0xFFEF4444); // Crimson/Red
      case NotificationType.bookingRescheduled:
        return const Color(0xFF3B82F6); // Blue/Indigo
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.newBooking:
        return Icons.event_available_rounded;
      case NotificationType.bookingCancelled:
        return Icons.event_busy_rounded;
      case NotificationType.bookingRescheduled:
        return Icons.update_rounded;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _getTypeColor();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? (isDark ? AppColors.darkSurface : AppColors.surface)
                  : (isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.8)
                      : AppColors.accent.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? (isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.6)
                        : AppColors.border.withValues(alpha: 0.6))
                    : AppColors.accent.withValues(alpha: 0.5),
                width: notification.isRead ? 1 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: typeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatTimeAgo(notification.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                              if (!notification.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                      if (notification.cancellationReason != null &&
                          notification.cancellationReason!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Reason: "${notification.cancellationReason}"',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
