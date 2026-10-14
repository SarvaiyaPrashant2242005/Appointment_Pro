import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/booking_model.dart';
import 'booking_status_chip.dart';

class BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final EdgeInsetsGeometry? margin;

  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onConfirm,
    this.onComplete,
    this.onCancel,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Resolve service name
    final services = ref.watch(servicesProvider).value ?? [];
    final service = services
        .where((s) => s.id == booking.serviceId)
        .firstOrNull;
    final serviceTitle =
        service?.name ?? booking.serviceName ?? 'Service';

    // Resolve staff name
    final staffList = ref.watch(staffProvider).value ?? [];
    final staff = staffList.where((s) => s.id == booking.staffId).firstOrNull;
    final staffName =
        staff?.name ??
        booking.staffName ??
        (booking.staffId != null ? 'Specialist' : 'Unassigned');

    // Date and time formatting
    final timeFormat = DateFormat('h:mm a');
    final timeRange =
        '${timeFormat.format(booking.startAt)} - ${timeFormat.format(booking.endAt)}';

    final now = DateTime.now();
    final isToday =
        booking.startAt.year == now.year &&
        booking.startAt.month == now.month &&
        booking.startAt.day == now.day;
    final isTomorrow =
        booking.startAt.year == now.year &&
        booking.startAt.month == now.month &&
        booking.startAt.day == now.day + 1;

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isTomorrow) {
      dateLabel = 'Tomorrow';
    } else {
      dateLabel = DateFormat('EEE, MMM d').format(booking.startAt);
    }

    final cardMargin =
        margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6);

    return Padding(
      padding: cardMargin,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Customer name + Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.customerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.fullPhoneNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    BookingStatusChip(status: booking.status),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                // Responsive Details Section
                if (isCompact) ...[
                  // Service & Staff
                  Row(
                    children: [
                      const Icon(
                        Icons.content_cut_rounded,
                        size: 15,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          serviceTitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          staffName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Time & Price Row (responsive wrap)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$dateLabel • $timeRange',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.accent
                                : const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      Text(
                        '\$${booking.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Wide side-by-side row
                  Row(
                    children: [
                      // Service & Staff
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.content_cut_rounded,
                                  size: 15,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    serviceTitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    staffName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Date, Time & Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$dateLabel • $timeRange',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.accent
                                    : const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${booking.price.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],

                // Action Buttons Section (Responsive & Support for Complete action)
                if (_hasActions) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Cancel action
                        if (booking.canCancel && onCancel != null)
                          TextButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Cancel'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),

                        // Confirm action for pending bookings
                        if (booking.canConfirm && onConfirm != null)
                          FilledButton.icon(
                            onPressed: onConfirm,
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Confirm'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.black,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                        // Complete action for confirmed bookings
                        if (booking.canComplete && onComplete != null)
                          FilledButton.icon(
                            onPressed: onComplete,
                            icon: const Icon(Icons.task_alt_rounded, size: 16),
                            label: const Text('Mark Completed'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _hasActions {
    if (booking.canConfirm && (onConfirm != null || onCancel != null)) {
      return true;
    }
    if (booking.canComplete && (onComplete != null || onCancel != null)) {
      return true;
    }
    return false;
  }
}
