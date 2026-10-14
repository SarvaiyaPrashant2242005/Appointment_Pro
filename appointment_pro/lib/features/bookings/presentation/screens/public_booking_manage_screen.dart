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
import '../../../../core/widgets/app_text_field.dart';
import '../../../availability/data/models/availability_model.dart';
import '../../../availability/presentation/providers/availability_provider.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../services/data/models/service_model.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/data/models/staff_model.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/booking_slot_model.dart';
import '../../data/utils/booking_availability_calculator.dart';
import '../../data/utils/booking_slug_helper.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_date_selector.dart';
import '../widgets/booking_status_chip.dart';
import '../widgets/booking_time_slots.dart';
import '../../../notifications/data/models/app_notification_model.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class PublicBookingManageScreen extends ConsumerStatefulWidget {
  final String businessSlug;
  final String? prefilledBookingId;

  const PublicBookingManageScreen({
    super.key,
    required this.businessSlug,
    this.prefilledBookingId,
  });

  @override
  ConsumerState<PublicBookingManageScreen> createState() =>
      _PublicBookingManageScreenState();
}

class _PublicBookingManageScreenState
    extends ConsumerState<PublicBookingManageScreen> {
  bool _isInitLoading = true;
  String? _businessError;
  BusinessModel? _business;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bookingIdController;
  final _phoneController = TextEditingController();

  bool _isSearching = false;
  String? _searchError;
  BookingModel? _verifiedBooking;

  @override
  void initState() {
    super.initState();
    _bookingIdController = TextEditingController(
      text: widget.prefilledBookingId ?? '',
    );
    Future.microtask(() => _loadBusiness());
  }

  @override
  void dispose() {
    _bookingIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    setState(() => _isInitLoading = true);
    try {
      final businessRepo = ref.read(businessRepositoryProvider);
      final businesses = await businessRepo.getBusinesses();

      final matched = businesses.where((b) {
        return BookingSlugHelper.matchesSlugOrId(b, widget.businessSlug);
      }).firstOrNull;

      if (matched == null) {
        setState(() {
          _business = null;
          _businessError = 'Business not found. Please verify the URL.';
          _isInitLoading = false;
        });
        return;
      }

      setState(() {
        _business = matched;
        _businessError = null;
        _isInitLoading = false;
      });
    } catch (e) {
      setState(() {
        _business = null;
        _businessError = 'Failed to load business details: $e';
        _isInitLoading = false;
      });
    }
  }

  bool _normalizeAndMatchPhone(String inputPhone, BookingModel booking) {
    final cleanInput = inputPhone.replaceAll(RegExp(r'\D'), '');
    final cleanStored = booking.customerPhone.replaceAll(RegExp(r'\D'), '');
    final cleanFull = booking.fullPhoneNumber.replaceAll(RegExp(r'\D'), '');

    if (cleanInput.isEmpty || cleanStored.isEmpty) return false;

    // Direct match against cleaned local phone or cleaned full phone
    if (cleanStored == cleanInput || cleanFull == cleanInput) return true;

    // Match if cleanInput is suffix of stored full number (e.g. entered without country code)
    if (cleanInput.length >= 7 && cleanFull.endsWith(cleanInput)) return true;
    if (cleanStored.length >= 7 && cleanInput.endsWith(cleanStored)) {
      return true;
    }

    return false;
  }

  Future<void> _handleFindBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_business == null) return;

    final bookingId = _bookingIdController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final booking = await repo.getBookingById(bookingId);

      // Verify: booking must exist, belong to this business, and phone must match
      if (booking == null ||
          booking.businessId != _business!.id ||
          !_normalizeAndMatchPhone(phone, booking)) {
        // Do not leak existence
        setState(() {
          _verifiedBooking = null;
          _searchError =
              'Booking not found. Please check your booking ID and phone number.';
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _verifiedBooking = booking;
        _searchError = null;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _verifiedBooking = null;
        _searchError =
            'Booking not found. Please check your booking ID and phone number.';
        _isSearching = false;
      });
    }
  }

  Future<void> _handleCancelBooking() async {
    final booking = _verifiedBooking;
    if (booking == null || !booking.canCancel) return;

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
                  color: AppColors.error.withValues(alpha: 0.12),
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
                'Are you sure you want to cancel your appointment? This action cannot be undone, and your time slot will be released for other clients.',
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
                  labelText: 'Reason for Cancellation (Optional)',
                  hintText: 'e.g., Schedule conflict, feeling unwell...',
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
                'Keep Appointment',
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

    setState(() => _isSearching = true);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final updated = await repo.updateBookingStatus(
        booking.id,
        BookingStatus.cancelled,
        cancellationReason: reason,
      );

      // Refresh owner bookings if active
      try {
        ref.read(bookingsProvider.notifier).refresh();
      } catch (_) {}

      // Dispatch FCM notification to Business Owner (Customer cancelled)
      try {
        final notifRepo = ref.read(notificationRepositoryProvider);
        await notifRepo.dispatchCustomerNotification(
          type: NotificationType.bookingCancelled,
          booking: updated,
          cancellationReason: reason,
        );
        ref.read(notificationsProvider.notifier).refresh();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _verifiedBooking = updated;
        _isSearching = false;
      });
      AppToast.info(context, 'Your appointment has been cancelled.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      AppToast.error(context, 'Failed to cancel appointment: $e');
    }
  }

  Future<void> _handleOpenReschedule() async {
    final booking = _verifiedBooking;
    if (booking == null || !booking.canReschedule || _business == null) return;

    // Load prerequisites
    final serviceRepo = ref.read(serviceRepositoryProvider);
    final staffRepo = ref.read(staffRepositoryProvider);
    final availRepo = ref.read(availabilityRepositoryProvider);
    final bookingRepo = ref.read(bookingRepositoryProvider);

    final services = await serviceRepo.getServices(_business!.id);
    final service = services
        .where((s) => s.id == booking.serviceId)
        .firstOrNull;

    if (service == null) {
      if (mounted) {
        AppToast.error(
          context,
          'Service details could not be found for rescheduling.',
        );
      }
      return;
    }

    final allStaff = await staffRepo.getStaff(_business!.id);
    final avail = await availRepo.getBusinessAvailability(_business!.id);
    final timeOffList = await availRepo.getTimeOffRecords(_business!.id);
    final existingBookings = await bookingRepo.getBookings(_business!.id);

    final eligibleStaff = allStaff.where((s) {
      if (!s.isActive) return false;
      if (s.assignedServiceIds.isEmpty) return true;
      return s.assignedServiceIds.contains(service.id);
    }).toList();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _RescheduleBottomSheet(
          booking: booking,
          business: _business!,
          service: service,
          eligibleStaff: eligibleStaff,
          availability: avail,
          timeOffList: timeOffList,
          existingBookings: existingBookings,
          onRescheduled: (updatedBooking) {
            setState(() {
              _verifiedBooking = updatedBooking;
            });
            ref.read(bookingsProvider.notifier).refresh();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isInitLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Appointment')),
        body: const Center(child: AppLoader()),
      );
    }

    if (_businessError != null || _business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Appointment')),
        body: AppEmptyView(
          icon: Icons.storefront_outlined,
          title: 'Business Unavailable',
          message: _businessError ?? 'Could not find business.',
          actionLabel: 'Return Home',
          onAction: () => context.go('/'),
        ),
      );
    }

    final business = _business!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              business.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Manage Appointment',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accent,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/book/${widget.businessSlug}'),
            child: const Text('New Booking'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Local Prototype Disclaimer Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
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
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Local Prototype Notice: Booking records are stored only in this browser\'s local storage and are not synchronized across other devices or browsers.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_verifiedBooking == null) ...[
                // Search Form
                _buildSearchForm(context, theme, isDark),
              ] else ...[
                // Verified Booking Details View
                _buildVerifiedBookingView(context, theme, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm(BuildContext context, ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Appointment',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your Booking ID and the customer phone number provided during booking to view, reschedule, or cancel your appointment.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Booking ID',
                  hint: 'e.g., bk_1728938492000',
                  controller: _bookingIdController,
                  prefixIcon: const Icon(Icons.tag_rounded),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Booking ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Customer Phone Number',
                  hint: 'e.g., 5551234567 or +1 5551234567',
                  controller: _phoneController,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Phone number is required for verification';
                    }
                    if (v.replaceAll(RegExp(r'\D'), '').length < 6) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                if (_searchError != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Verify & Manage Appointment',
                  icon: Icons.search_rounded,
                  isLoading: _isSearching,
                  onPressed: _handleFindBooking,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBookingView(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final booking = _verifiedBooking!;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Verified booking for ${_business!.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Look Up Another'),
              onPressed: () {
                setState(() {
                  _verifiedBooking = null;
                  _searchError = null;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Booking Header Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Reference ID',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      SelectableText(
                        booking.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: booking.id));
                          AppToast.info(context, 'ID copied to clipboard');
                        },
                        child: const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              BookingStatusChip(status: booking.status),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Appointment Information
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: dateFormat.format(booking.startAt),
                isDark: isDark,
              ),
              const Divider(height: 20),
              _buildRow(
                icon: Icons.schedule_rounded,
                label: 'Time',
                value:
                    '${timeFormat.format(booking.startAt)} - ${timeFormat.format(booking.endAt)} (${booking.durationMinutes} min)',
                isDark: isDark,
              ),
              const Divider(height: 20),
              _buildRow(
                icon: Icons.content_cut_rounded,
                label: 'Service',
                value: booking.serviceName ?? 'Service #${booking.serviceId}',
                isDark: isDark,
              ),
              const Divider(height: 20),
              _buildRow(
                icon: Icons.person_rounded,
                label: 'Specialist',
                value:
                    booking.staffName ??
                    (booking.staffId != null
                        ? 'Staff #${booking.staffId}'
                        : 'Auto-assigned Specialist'),
                isDark: isDark,
              ),
              const Divider(height: 20),
              _buildRow(
                icon: Icons.payments_outlined,
                label: 'Price',
                value: '\$${booking.price.toStringAsFixed(2)}',
                valueColor: AppColors.success,
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Customer Details Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow(
                icon: Icons.badge_outlined,
                label: 'Client Name',
                value: booking.customerName,
                isDark: isDark,
              ),
              const Divider(height: 20),
              _buildRow(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: booking.fullPhoneNumber,
                isDark: isDark,
              ),
              if (booking.customerEmail != null &&
                  booking.customerEmail!.isNotEmpty) ...[
                const Divider(height: 20),
                _buildRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: booking.customerEmail!,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),

        // Cancellation Information Card
        if (booking.isCancelled) ...[
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'This appointment was cancelled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                if (booking.cancelledAt != null) ...[
                  _buildRow(
                    icon: Icons.event_busy_rounded,
                    label: 'Cancelled On',
                    value: DateFormat(
                      'MMM d, yyyy  h:mm a',
                    ).format(booking.cancelledAt!),
                    isDark: isDark,
                  ),
                  const Divider(height: 18),
                ],
                _buildRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Cancellation Reason',
                  value:
                      (booking.cancellationReason != null &&
                          booking.cancellationReason!.isNotEmpty)
                      ? booking.cancellationReason!
                      : 'No reason provided',
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                Text(
                  'The reserved slot has been released back into availability.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Reschedule History Card
        if (booking.rescheduleHistory.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Reschedule History (${booking.rescheduleHistory.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < booking.rescheduleHistory.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  _buildRescheduleHistoryItem(
                    booking.rescheduleHistory[i],
                    index: i + 1,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],

        if (booking.isCompleted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This appointment has already been completed.',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Eligible Actions
        if (booking.canReschedule) ...[
          AppButton(
            label: 'Reschedule Appointment',
            icon: Icons.edit_calendar_rounded,
            onPressed: _handleOpenReschedule,
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
              onPressed: _handleCancelBooking,
            ),
          ),
          const SizedBox(height: 12),
        ],

        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => context.go('/book/${widget.businessSlug}'),
          child: const Text('Back to Booking Page'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.accent : AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRescheduleHistoryItem(
    RescheduleRecord record, {
    required int index,
    required bool isDark,
  }) {
    final format = DateFormat('MMM d, h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reschedule #$index',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'From: ${format.format(record.previousStartAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'To: ${format.format(record.newStartAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        if (record.reason != null && record.reason!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Reason: "${record.reason}"',
            style: TextStyle(
              fontSize: 11.5,
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
}

/// Bottom Sheet for Customer Rescheduling
class _RescheduleBottomSheet extends StatefulWidget {
  final BookingModel booking;
  final BusinessModel business;
  final ServiceModel service;
  final List<StaffModel> eligibleStaff;
  final BusinessAvailability availability;
  final List<TimeOffRecord> timeOffList;
  final List<BookingModel> existingBookings;
  final ValueChanged<BookingModel> onRescheduled;

  const _RescheduleBottomSheet({
    required this.booking,
    required this.business,
    required this.service,
    required this.eligibleStaff,
    required this.availability,
    required this.timeOffList,
    required this.existingBookings,
    required this.onRescheduled,
  });

  @override
  State<_RescheduleBottomSheet> createState() => _RescheduleBottomSheetState();
}

class _RescheduleBottomSheetState extends State<_RescheduleBottomSheet> {
  late DateTime _selectedDate;
  StaffModel? _selectedStaff;
  BookingSlot? _selectedSlot;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Start date at least today or original booking date if future
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(
      widget.booking.startAt.year,
      widget.booking.startAt.month,
      widget.booking.startAt.day,
    );
    _selectedDate = bookingDay.isAfter(today) ? bookingDay : today;

    // Retain initial staff if eligible
    if (widget.booking.staffId != null) {
      _selectedStaff = widget.eligibleStaff
          .where((s) => s.id == widget.booking.staffId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<BookingSlot> _computeSlots() {
    return BookingAvailabilityCalculator.calculateAvailableSlots(
      date: _selectedDate,
      service: widget.service,
      availability: widget.availability,
      timeOffList: widget.timeOffList,
      eligibleStaff: widget.eligibleStaff,
      existingBookings: widget.existingBookings,
      requestedStaffId: _selectedStaff?.id,
      ignoreBookingId: widget.booking.id, // Current booking slot is ignored!
    );
  }

  Future<void> _handleConfirmReschedule(List<BookingSlot> currentSlots) async {
    final slot = _selectedSlot;
    if (slot == null) {
      AppToast.warning(context, 'Please select an available time slot.');
      return;
    }

    // Determine assigned staff ID
    String? assignedStaffId = _selectedStaff?.id;
    assignedStaffId ??= BookingAvailabilityCalculator.selectBestStaffForSlot(
      availableStaffIds: slot.availableStaffIds,
      existingBookingsForDay: widget.existingBookings.where((b) {
        return b.startAt.year == _selectedDate.year &&
            b.startAt.month == _selectedDate.month &&
            b.startAt.day == _selectedDate.day &&
            b.id != widget.booking.id;
      }).toList(),
    );

    assignedStaffId ??= slot.availableStaffIds.firstOrNull;

    if (assignedStaffId == null) {
      AppToast.error(
        context,
        'No specialist is available for this slot. Please select another.',
      );
      return;
    }

    // Immediate revalidation before saving
    final isStillAvailable = BookingAvailabilityCalculator.isSlotStillAvailable(
      startAt: slot.startAt,
      endAt: slot.endAt,
      bufferMinutes: widget.service.bufferMinutes,
      staffId: assignedStaffId,
      existingBookings: widget.existingBookings,
      ignoreBookingId: widget.booking.id,
    );

    if (!isStillAvailable) {
      AppToast.error(
        context,
        'This slot was just taken. Please select a different time slot.',
      );
      setState(() => _selectedSlot = null);
      return;
    }

    final staffObj = widget.eligibleStaff
        .where((s) => s.id == assignedStaffId)
        .firstOrNull;

    setState(() => _isSubmitting = true);

    try {
      final consumerRef = ProviderScope.containerOf(context);
      final repo = consumerRef.read(bookingRepositoryProvider);

      final updated = await repo.rescheduleBooking(
        bookingId: widget.booking.id,
        newStartAt: slot.startAt,
        newEndAt: slot.endAt,
        newStaffId: assignedStaffId,
        newStaffName: staffObj?.name,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      // Dispatch FCM notification to Business Owner (Customer rescheduled)
      try {
        final notifRepo = consumerRef.read(notificationRepositoryProvider);
        await notifRepo.dispatchCustomerNotification(
          type: NotificationType.bookingRescheduled,
          booking: updated,
          oldStartAt: widget.booking.startAt,
        );
        consumerRef.read(notificationsProvider.notifier).refresh();
      } catch (_) {}

      if (!mounted) return;
      widget.onRescheduled(updated);
      Navigator.of(context).pop();
      AppToast.success(context, 'Appointment rescheduled successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppToast.error(context, 'Rescheduling failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slots = _computeSlots();
    final timeFormat = DateFormat('EEE, MMM d, h:mm a');

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reschedule Appointment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.service.name} (${widget.service.durationMinutes} min)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Main Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Original Appointment Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              timeFormat.format(widget.booking.startAt),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 1. Date Selector
                    Text(
                      'Select New Date',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BookingDateSelector(
                      selectedDate: _selectedDate,
                      daysAhead: 30,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                          _selectedSlot = null;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // 2. Staff Selector (if applicable)
                    if (widget.eligibleStaff.length > 1) ...[
                      Text(
                        'Select Specialist (Optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Any Specialist'),
                              selected: _selectedStaff == null,
                              onSelected: (_) {
                                setState(() {
                                  _selectedStaff = null;
                                  _selectedSlot = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ...widget.eligibleStaff.map((staff) {
                              final isSelected = _selectedStaff?.id == staff.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(staff.name),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedStaff = staff;
                                      _selectedSlot = null;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 3. Time Slots
                    Text(
                      'Select New Time Slot',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BookingTimeSlots(
                      slots: slots,
                      selectedSlot: _selectedSlot,
                      onSlotSelected: (slot) {
                        setState(() => _selectedSlot = slot);
                      },
                    ),

                    if (_selectedSlot != null) ...[
                      const SizedBox(height: 20),

                      // Time Change Summary Card
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reschedule Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Original Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeFormat.format(
                                          widget.booking.startAt,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'New Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeFormat.format(
                                          _selectedSlot!.startAt,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Reason for Rescheduling (Optional)',
                          hintText: 'e.g., Requested by customer',
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkBackground
                              : AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Bottom Confirmation Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: AppButton(
                  label: 'Confirm Reschedule',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _selectedSlot == null
                      ? null
                      : () => _handleConfirmReschedule(slots),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
