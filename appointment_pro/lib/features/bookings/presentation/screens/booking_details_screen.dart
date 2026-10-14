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
import '../../../availability/presentation/providers/availability_provider.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_reschedule_sheet.dart';
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

  Future<void> _handleReschedule(BookingModel booking) async {
    setState(() => _isLoading = true);
    try {
      final businessRepo = ref.read(businessRepositoryProvider);
      final serviceRepo = ref.read(serviceRepositoryProvider);
      final staffRepo = ref.read(staffRepositoryProvider);
      final availRepo = ref.read(availabilityRepositoryProvider);
      final bookingRepo = ref.read(bookingRepositoryProvider);

      final businesses = await businessRepo.getBusinesses();
      final business = businesses.where((b) => b.id == booking.businessId).firstOrNull ??
          ref.read(activeBusinessProvider);

      if (business == null) {
        if (!mounted) return;
        AppToast.error(context, 'Business details could not be found.');
        return;
      }

      final services = await serviceRepo.getServices(business.id);
      final service =
          services.where((s) => s.id == booking.serviceId).firstOrNull;

      if (service == null) {
        if (!mounted) return;
        AppToast.error(
          context,
          'Service details could not be found for rescheduling.',
        );
        return;
      }

      final allStaff = await staffRepo.getStaff(business.id);
      final avail = await availRepo.getBusinessAvailability(business.id);
      final timeOffList = await availRepo.getTimeOffRecords(business.id);
      final existingBookings = await bookingRepo.getBookings(business.id);

      final eligibleStaff = allStaff.where((s) {
        if (!s.isActive) return false;
        if (s.assignedServiceIds.isEmpty) return true;
        return s.assignedServiceIds.contains(service.id);
      }).toList();

      if (!mounted) return;

      final updated = await BookingRescheduleSheet.show(
        context: context,
        booking: booking,
        business: business,
        service: service,
        eligibleStaff: eligibleStaff,
        availability: avail,
        timeOffList: timeOffList,
        existingBookings: existingBookings,
      );

      if (updated != null && mounted) {
        ref.read(bookingsProvider.notifier).refresh();
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to open reschedule: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancel(BookingModel booking) async {
    final reasonController = TextEditingController();
    bool confirmed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cancel Appointment',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel the booking for ${booking.customerName}? This will immediately release the time slot and update booking status to cancelled.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Cancellation Reason (Optional)',
                  hintText: 'e.g., Customer requested cancellation',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Keep Booking',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                confirmed = true;
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel Appointment'),
            ),
          ],
        );
      },
    );

    if (!confirmed) return;

    final reason = reasonController.text.trim().isEmpty
        ? null
        : reasonController.text.trim();

    setState(() => _isLoading = true);
    try {
      await ref
          .read(bookingsProvider.notifier)
          .cancelBooking(booking.id, reason: reason);
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
          if (booking.canReschedule)
            IconButton(
              tooltip: 'Reschedule Appointment',
              icon: const Icon(Icons.edit_calendar_rounded, size: 20),
              onPressed: () => _handleReschedule(booking),
            ),
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
                              service?.name ??
                              booking.serviceName ??
                              'Service',
                          subtitle: service?.description,
                          context: context,
                        ),
                        const Divider(height: 20),
                        _buildDetailRow(
                          icon: Icons.person_rounded,
                          label: 'Specialist / Staff',
                          value:
                              staff?.name ??
                              booking.staffName ??
                              'Auto-assigned',
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

                  // Reschedule History Section
                  if (booking.rescheduleHistory.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Reschedule History (${booking.rescheduleHistory.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (
                            int i = 0;
                            i < booking.rescheduleHistory.length;
                            i++
                          ) ...[
                            if (i > 0) const Divider(height: 24),
                            _buildRescheduleHistoryItem(
                              booking.rescheduleHistory[i],
                              index: i + 1,
                              context: context,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Cancellation Details Card
                  if (booking.isCancelled) ...[
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cancel_outlined,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Cancellation Information',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          if (booking.cancelledAt != null) ...[
                            _buildDetailRow(
                              icon: Icons.event_busy_rounded,
                              label: 'Cancelled On',
                              value: DateFormat(
                                'MMM d, yyyy  h:mm a',
                              ).format(booking.cancelledAt!),
                              context: context,
                            ),
                            const Divider(height: 20),
                          ],
                          _buildDetailRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Reason',
                            value:
                                (booking.cancellationReason != null &&
                                    booking.cancellationReason!.isNotEmpty)
                                ? booking.cancellationReason!
                                : 'No specific reason provided',
                            context: context,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The original time slot has been released back into availability.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Actions Section
                  if (booking.canComplete) ...[
                    AppButton(
                      label: 'Mark as Completed',
                      icon: Icons.task_alt_rounded,
                      onPressed: () => _handleComplete(booking),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (booking.canReschedule) ...[
                    AppButton(
                      label: 'Reschedule Appointment',
                      icon: Icons.edit_calendar_rounded,
                      isOutlined: true,
                      onPressed: () => _handleReschedule(booking),
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

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildRescheduleHistoryItem(
    RescheduleRecord record, {
    required int index,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeFormat = DateFormat('MMM d, h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reschedule #$index',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              DateFormat('MMM d, yyyy  h:mm a').format(record.rescheduledAt),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormat.format(record.previousStartAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded, size: 16),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rescheduled To',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormat.format(record.newStartAt),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (record.reason != null && record.reason!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Reason: "${record.reason}"',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ],
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
