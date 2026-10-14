import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../availability/data/models/availability_model.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../../../services/data/models/service_model.dart';
import '../../../staff/data/models/staff_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/booking_slot_model.dart';
import '../../data/utils/booking_availability_calculator.dart';
import '../providers/booking_provider.dart';
import 'booking_date_selector.dart';
import 'booking_time_slots.dart';

class BookingRescheduleSheet extends StatefulWidget {
  final BookingModel booking;
  final BusinessModel business;
  final ServiceModel service;
  final List<StaffModel> eligibleStaff;
  final BusinessAvailability availability;
  final List<TimeOffRecord> timeOffList;
  final List<BookingModel> existingBookings;
  final ValueChanged<BookingModel>? onRescheduled;

  const BookingRescheduleSheet({
    super.key,
    required this.booking,
    required this.business,
    required this.service,
    required this.eligibleStaff,
    required this.availability,
    required this.timeOffList,
    required this.existingBookings,
    this.onRescheduled,
  });

  static Future<BookingModel?> show({
    required BuildContext context,
    required BookingModel booking,
    required BusinessModel business,
    required ServiceModel service,
    required List<StaffModel> eligibleStaff,
    required BusinessAvailability availability,
    required List<TimeOffRecord> timeOffList,
    required List<BookingModel> existingBookings,
    ValueChanged<BookingModel>? onRescheduled,
  }) {
    return showModalBottomSheet<BookingModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingRescheduleSheet(
        booking: booking,
        business: business,
        service: service,
        eligibleStaff: eligibleStaff,
        availability: availability,
        timeOffList: timeOffList,
        existingBookings: existingBookings,
        onRescheduled: onRescheduled,
      ),
    );
  }

  @override
  State<BookingRescheduleSheet> createState() => _BookingRescheduleSheetState();
}

class _BookingRescheduleSheetState extends State<BookingRescheduleSheet> {
  late DateTime _selectedDate;
  StaffModel? _selectedStaff;
  BookingSlot? _selectedSlot;
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(
      widget.booking.startAt.year,
      widget.booking.startAt.month,
      widget.booking.startAt.day,
    );
    _selectedDate = bookingDay.isAfter(today) ? bookingDay : today;

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
      ignoreBookingId: widget.booking.id, // Current slot doesn't conflict!
    );
  }

  Future<void> _handleConfirmReschedule(List<BookingSlot> currentSlots) async {
    final slot = _selectedSlot;
    if (slot == null) {
      AppToast.warning(context, 'Please select an available time slot.');
      return;
    }

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

    // Revalidate slot right before saving
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

      // Refresh bookings provider if owner view is active
      try {
        consumerRef.read(bookingsProvider.notifier).refresh();
      } catch (_) {}

      if (!mounted) return;
      widget.onRescheduled?.call(updated);
      Navigator.of(context).pop(updated);
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

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Current appointment box
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

                    // Date Selection
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

                    // Staff Selection
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
                              final isSelected =
                                  _selectedStaff?.id == staff.id;
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

                    // Time Slot Selection
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

                      // Comparison card
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
                          hintText: 'e.g., Requested by customer or schedule update',
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
