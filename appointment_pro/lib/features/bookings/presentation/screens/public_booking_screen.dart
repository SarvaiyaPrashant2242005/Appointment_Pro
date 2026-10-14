import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../providers/public_booking_provider.dart';
import '../widgets/booking_date_selector.dart';
import '../widgets/booking_service_selector.dart';
import '../widgets/booking_staff_selector.dart';
import '../widgets/booking_status_chip.dart';
import '../widgets/booking_time_slots.dart';
import '../widgets/customer_details_form.dart';

class PublicBookingScreen extends ConsumerStatefulWidget {
  final String businessSlug;

  const PublicBookingScreen({super.key, required this.businessSlug});

  @override
  ConsumerState<PublicBookingScreen> createState() =>
      _PublicBookingScreenState();
}

class _PublicBookingScreenState extends ConsumerState<PublicBookingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(publicBookingProvider.notifier).init(widget.businessSlug);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(publicBookingProvider);
    final notifier = ref.read(publicBookingProvider.notifier);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: AppLoader()),
      );
    }

    if (state.errorMessage != null && state.business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: AppEmptyView(
          icon: Icons.storefront_outlined,
          title: 'Business Unavailable',
          message: state.errorMessage!,
          actionLabel: 'Return to App',
          onAction: () => context.go('/'),
        ),
      );
    }

    final business = state.business!;

    return WillPopScope(
      onWillPop: () async {
        if (state.currentStep == PublicBookingStep.service ||
            state.currentStep == PublicBookingStep.success) {
          return true;
        }
        _handleBack(state, notifier);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading:
              state.currentStep != PublicBookingStep.service &&
                  state.currentStep != PublicBookingStep.success
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBack(state, notifier),
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                business.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Online Booking',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.manage_search_rounded, size: 18),
              label: const Text('Manage Booking'),
              onPressed: () {
                context.push('/book/${widget.businessSlug}/manage');
              },
            ),
            if (state.currentStep != PublicBookingStep.success)
              TextButton(
                onPressed: () => notifier.resetFlow(),
                child: const Text('Start Over'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Step Progress Indicator (if not on success)
              if (state.currentStep != PublicBookingStep.success)
                _buildProgressHeader(context, state),

              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStepContent(context, state, notifier),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(PublicBookingState state, PublicBookingNotifier notifier) {
    switch (state.currentStep) {
      case PublicBookingStep.staff:
        notifier.goToStep(PublicBookingStep.service);
        break;
      case PublicBookingStep.dateTime:
        notifier.goToStep(PublicBookingStep.staff);
        break;
      case PublicBookingStep.customerDetails:
        notifier.goToStep(PublicBookingStep.dateTime);
        break;
      case PublicBookingStep.review:
        notifier.goToStep(PublicBookingStep.customerDetails);
        break;
      default:
        break;
    }
  }

  Widget _buildProgressHeader(BuildContext context, PublicBookingState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      'Service',
      'Specialist',
      'Date & Time',
      'Details',
      'Confirm',
    ];

    final currentIndex = state.currentStep.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentIndex;
          final isCurrent = index == currentIndex;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? AppColors.accent
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.accent
                              : (isCompleted
                                    ? (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary)
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent(
    BuildContext context,
    PublicBookingState state,
    PublicBookingNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (state.currentStep) {
      // Step 2: Select Service
      case PublicBookingStep.service:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Intro Banner
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent.withOpacity(0.15),
                    child: Text(
                      state.business!.name.isNotEmpty
                          ? state.business!.name.substring(0, 1).toUpperCase()
                          : 'B',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.business!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.business!.type.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            state.business!.type,
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
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Select a Service',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the service you would like to book today.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            BookingServiceSelector(
              services: state.services,
              selectedService: state.selectedService,
              onSelect: notifier.selectService,
            ),
          ],
        );

      // Step 3: Select Staff
      case PublicBookingStep.staff:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected service summary chip
            _buildServiceSummaryCard(context, state.selectedService!),
            const SizedBox(height: 20),

            Text(
              'Select Specialist',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose your preferred professional or let us pick an available specialist.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            BookingStaffSelector(
              eligibleStaff: state.eligibleStaff,
              selectedStaff: state.selectedStaff,
              onSelect: notifier.selectStaff,
            ),
          ],
        );

      // Step 4: Select Date & Time
      case PublicBookingStep.dateTime:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service & Staff Summary
            _buildServiceSummaryCard(context, state.selectedService!),
            const SizedBox(height: 16),

            Text(
              'Select Date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            BookingDateSelector(
              selectedDate: state.selectedDate,
              onDateSelected: notifier.selectDate,
            ),

            const SizedBox(height: 24),
            Text(
              'Available Times (${DateFormat('EEE, MMM d').format(state.selectedDate)})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Showing slots calculated against working hours, breaks, and specialist schedules.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            BookingTimeSlots(
              slots: state.availableSlots,
              selectedSlot: state.selectedSlot,
              onSlotSelected: notifier.selectSlot,
            ),
          ],
        );

      // Step 5: Customer Details
      case PublicBookingStep.customerDetails:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSlotSummaryCard(context, state),
            const SizedBox(height: 20),

            Text(
              'Your Contact Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We will use this information to send booking confirmations and appointment updates.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            CustomerDetailsForm(
              initialName: state.customerName,
              initialCountryCode: state.customerCountryCode,
              initialPhone: state.customerPhone,
              initialEmail: state.customerEmail,
              initialNotes: state.customerNotes,
              onSubmit:
                  ({
                    required String name,
                    required String countryCode,
                    required String phone,
                    String? email,
                    String? notes,
                  }) {
                    notifier.setCustomerDetails(
                      name: name,
                      countryCode: countryCode,
                      phone: phone,
                      email: email,
                      notes: notes,
                    );
                  },
            ),
          ],
        );

      // Step 6: Review & Confirmation
      case PublicBookingStep.review:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Confirm Appointment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Please review your appointment summary before submitting.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Appointment Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.selectedService!.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${state.selectedService!.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildReviewRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat(
                      'EEEE, MMMM d, yyyy',
                    ).format(state.selectedDate),
                  ),
                  const SizedBox(height: 10),
                  _buildReviewRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value:
                        '${state.selectedSlot!.formattedTime} (${state.selectedService!.durationMinutes} min)',
                  ),
                  const SizedBox(height: 10),
                  _buildReviewRow(
                    icon: Icons.person_rounded,
                    label: 'Specialist',
                    value:
                        state.selectedStaff?.name ??
                        'Any Available Specialist (Auto-assigned)',
                  ),
                  const SizedBox(height: 10),
                  _buildReviewRow(
                    icon: Icons.storefront_rounded,
                    label: 'Business',
                    value: state.business!.name,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Customer Details Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 16),
                  _buildReviewRow(
                    icon: Icons.badge_outlined,
                    label: 'Name',
                    value: state.customerName,
                  ),
                  const SizedBox(height: 10),
                  _buildReviewRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value:
                        '${state.customerCountryCode} ${state.customerPhone}',
                  ),
                  if (state.customerEmail != null &&
                      state.customerEmail!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildReviewRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: state.customerEmail!,
                    ),
                  ],
                  if (state.customerNotes != null &&
                      state.customerNotes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildReviewRow(
                      icon: Icons.note_outlined,
                      label: 'Notes',
                      value: state.customerNotes!,
                    ),
                  ],
                ],
              ),
            ),

            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            AppButton(
              label: 'Confirm & Book Appointment',
              icon: Icons.check_circle_outline,
              isLoading: state.isSubmitting,
              onPressed: () => notifier.submitBooking(),
            ),
          ],
        );

      // Step 7: Booking Success View
      case PublicBookingStep.success:
        final booking = state.confirmedBooking;

        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking Confirmed!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Your appointment with ${state.business!.name} has been successfully reserved.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Confirmation Ticket Card
            if (booking != null) ...[
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SelectableText(
                              booking.id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        BookingStatusChip(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: booking.id));
                        AppToast.info(
                          context,
                          'Booking ID copied to clipboard',
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Copy Booking ID',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    _buildReviewRow(
                      icon: Icons.content_cut_rounded,
                      label: 'Service',
                      value:
                          state.selectedService?.name ??
                          (booking.serviceName ?? 'Service'),
                    ),
                    const SizedBox(height: 12),
                    _buildReviewRow(
                      icon: Icons.storefront_rounded,
                      label: 'Business',
                      value: state.business!.name,
                    ),
                    const SizedBox(height: 12),
                    _buildReviewRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Appointment Date & Time',
                      value:
                          '${DateFormat('EEEE, MMMM d, yyyy').format(booking.startAt)}\n${DateFormat('h:mm a').format(booking.startAt)} - ${DateFormat('h:mm a').format(booking.endAt)}',
                    ),
                    const SizedBox(height: 12),
                    _buildReviewRow(
                      icon: Icons.badge_outlined,
                      label: 'Customer Name',
                      value: booking.customerName,
                    ),
                    if (booking.staffName != null ||
                        state.selectedStaff != null) ...[
                      const SizedBox(height: 12),
                      _buildReviewRow(
                        icon: Icons.person_rounded,
                        label: 'Specialist',
                        value:
                            state.selectedStaff?.name ??
                            booking.staffName ??
                            'Staff Specialist',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Important customer notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Important: Please save your Booking ID. You will need your Booking ID and phone number to look up, reschedule, or cancel your appointment.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Manage / Reschedule Booking primary action
              AppButton(
                label: 'Manage or Reschedule Booking',
                icon: Icons.edit_calendar_rounded,
                onPressed: () {
                  context.push(
                    '/book/${widget.businessSlug}/manage?bookingId=${booking.id}',
                  );
                },
              ),
              const SizedBox(height: 12),
            ],

            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Book Another Appointment'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => notifier.resetFlow(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        );
    }
  }

  Widget _buildServiceSummaryCard(BuildContext context, dynamic service) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            '\$${service.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotSummaryCard(BuildContext context, PublicBookingState state) {
    final dateFormat = DateFormat('EEE, MMM d');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: AppColors.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${state.selectedService!.name} • ${dateFormat.format(state.selectedDate)} at ${state.selectedSlot!.formattedTime}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
