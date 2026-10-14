import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_status_chip.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirm(BookingModel booking) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingsProvider.notifier).confirmBooking(booking.id);
      if (!mounted) return;
      AppToast.success(context, 'Booking confirmed.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to confirm booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleComplete(BookingModel booking) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(bookingsProvider.notifier).completeBooking(booking.id);
      if (!mounted) return;
      AppToast.success(context, 'Booking marked as completed.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to complete booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleNoShow(BookingModel booking) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Mark as No-Show',
      message:
          'Did customer ${booking.customerName} fail to attend the appointment?',
      confirmText: 'Mark No-Show',
      cancelText: 'Dismiss',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(bookingsProvider.notifier).markNoShow(booking.id);
      if (!mounted) return;
      AppToast.warning(context, 'Booking marked as no-show.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to update booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancel(BookingModel booking) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Cancel Appointment',
      message:
          'Are you sure you want to cancel the booking for ${booking.customerName}? This will immediately release the time slot.',
      confirmText: 'Cancel Appointment',
      cancelText: 'Keep',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(bookingsProvider.notifier).cancelBooking(booking.id);
      if (!mounted) return;
      AppToast.info(context, 'Booking has been cancelled.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to cancel booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final booking = ref.watch(bookingByIdProvider(widget.bookingId));

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: AppEmptyView(
          icon: Icons.search_off_rounded,
          title: 'Booking Not Found',
          message:
              'The requested booking record could not be found or has been deleted.',
          actionLabel: 'Back to Bookings',
          onAction: () => context.pop(),
        ),
      );
    }

    // Resolve service and staff
    final services = ref.watch(servicesProvider).value ?? [];
    final service = services
        .where((s) => s.id == booking.serviceId)
        .firstOrNull;

    final staffList = ref.watch(staffProvider).value ?? [];
    final staff = staffList.where((s) => s.id == booking.staffId).firstOrNull;

    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            tooltip: 'Copy Reference ID',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: booking.id));
              AppToast.info(context, 'Booking ID copied to clipboard');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoader())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner with Status & Reference
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reference ID',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        BookingStatusChip(status: booking.status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Appointment Information Card
                  Text(
                    'Appointment Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: dateFormat.format(booking.startAt),
                          context: context,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Time',
                          value:
                              '${timeFormat.format(booking.startAt)} - ${timeFormat.format(booking.endAt)} (${booking.durationMinutes} min)',
                          context: context,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.content_cut_rounded,
                          label: 'Service',
                          value:
                              service?.name ?? 'Service #${booking.serviceId}',
                          subtitle: service?.description,
                          context: context,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.person_rounded,
                          label: 'Specialist / Staff',
                          value:
                              staff?.name ??
                              (booking.staffId != null
                                  ? 'Staff #${booking.staffId}'
                                  : 'Auto-assigned'),
                          context: context,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Total Price',
                          value: '\$${booking.price.toStringAsFixed(2)}',
                          valueColor: AppColors.success,
                          context: context,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Customer Information Card
                  Text(
                    'Customer Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.badge_outlined,
                          label: 'Customer Name',
                          value: booking.customerName,
                          context: context,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: booking.fullPhoneNumber,
                          actionIcon: Icons.copy,
                          onAction: () {
                            Clipboard.setData(
                              ClipboardData(text: booking.fullPhoneNumber),
                            );
                            AppToast.info(context, 'Phone copied');
                          },
                          context: context,
                        ),
                        if (booking.customerEmail != null &&
                            booking.customerEmail!.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildDetailRow(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            value: booking.customerEmail!,
                            actionIcon: Icons.copy,
                            onAction: () {
                              Clipboard.setData(
                                ClipboardData(text: booking.customerEmail!),
                              );
                              AppToast.info(context, 'Email copied');
                            },
                            context: context,
                          ),
                        ],
                        if (booking.customerNotes != null &&
                            booking.customerNotes!.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildDetailRow(
                            icon: Icons.note_outlined,
                            label: 'Customer Notes',
                            value: booking.customerNotes!,
                            context: context,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Metadata Card
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Created At',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MMM d, yyyy  h:mm a',
                          ).format(booking.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Actions Section
                  if (booking.canConfirm) ...[
                    AppButton(
                      label: 'Confirm Booking',
                      icon: Icons.check_circle_outline,
                      onPressed: () => _handleConfirm(booking),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (booking.canComplete) ...[
                    AppButton(
                      label: 'Mark as Completed',
                      icon: Icons.task_alt_rounded,
                      onPressed: () => _handleComplete(booking),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (booking.canMarkNoShow) ...[
                    AppButton(
                      label: 'Mark as No-Show',
                      icon: Icons.person_off_outlined,
                      isOutlined: true,
                      onPressed: () => _handleNoShow(booking),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (booking.canCancel) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel Appointment'),
                        onPressed: () => _handleCancel(booking),
                      ),
                    ),
                  ],

                  if (booking.isCompleted) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '✓ This appointment has been completed successfully.',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (booking.isCancelled) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '✕ This appointment was cancelled.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    Color? valueColor,
    IconData? actionIcon,
    VoidCallback? onAction,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.accent : AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionIcon != null && onAction != null)
          IconButton(
            icon: Icon(actionIcon, size: 18),
            onPressed: onAction,
            visualDensity: VisualDensity.compact,
            color: isDark ? AppColors.accent : AppColors.primary,
          ),
      ],
    );
  }
}
