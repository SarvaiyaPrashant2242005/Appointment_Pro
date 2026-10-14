import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../services/presentation/providers/service_provider.dart';
import '../../../staff/presentation/providers/staff_provider.dart';
import '../../data/models/booking_model.dart';
import 'booking_status_chip.dart';

class BookingCalendarView extends ConsumerStatefulWidget {
  final List<BookingModel> bookings;
  final ValueChanged<BookingModel>? onBookingTap;
  final Future<void> Function(BookingModel)? onConfirm;
  final Future<void> Function(BookingModel)? onComplete;
  final Future<void> Function(BookingModel)? onCancel;
  final Future<void> Function(BookingModel)? onReschedule;

  const BookingCalendarView({
    super.key,
    required this.bookings,
    this.onBookingTap,
    this.onConfirm,
    this.onComplete,
    this.onCancel,
    this.onReschedule,
  });

  @override
  ConsumerState<BookingCalendarView> createState() =>
      _BookingCalendarViewState();
}

class _BookingCalendarViewState extends ConsumerState<BookingCalendarView> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  List<BookingModel> _bookingsForDate(DateTime date) {
    return widget.bookings.where((b) {
      return b.startAt.year == date.year &&
          b.startAt.month == date.month &&
          b.startAt.day == date.day;
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  String _getServiceName(BookingModel booking) {
    if (booking.serviceName != null && booking.serviceName!.trim().isNotEmpty) {
      return booking.serviceName!;
    }
    final services = ref.watch(servicesProvider).value ?? [];
    final match = services.where((s) => s.id == booking.serviceId).firstOrNull;
    if (match != null && match.name.trim().isNotEmpty) {
      return match.name;
    }
    return 'Service';
  }

  String? _getStaffName(BookingModel booking) {
    if (booking.staffName != null && booking.staffName!.trim().isNotEmpty) {
      return booking.staffName;
    }
    if (booking.staffId != null) {
      final staffList = ref.watch(staffProvider).value ?? [];
      final match = staffList.where((s) => s.id == booking.staffId).firstOrNull;
      if (match != null && match.name.trim().isNotEmpty) {
        return match.name;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedDayBookings = _bookingsForDate(_selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header Bar with Navigation
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 28),
                      tooltip: 'Previous Month',
                      onPressed: _previousMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedMonth),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 28),
                      tooltip: 'Next Month',
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.today_rounded, size: 16),
                  label: const Text('Today'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.accent,
                  ),
                  onPressed: _goToToday,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Status Legend Strip (No pending state)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem('Confirmed', AppColors.accent),
                const SizedBox(width: 12),
                _buildLegendItem('Completed', AppColors.success),
                const SizedBox(width: 12),
                _buildLegendItem('Cancelled', AppColors.error),
                const SizedBox(width: 12),
                _buildLegendItem('No-Show', AppColors.textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Calendar Grid Card
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Weekday Headers
                Row(
                  children: const [
                    Expanded(child: _WeekdayHeader(label: 'Mon')),
                    Expanded(child: _WeekdayHeader(label: 'Tue')),
                    Expanded(child: _WeekdayHeader(label: 'Wed')),
                    Expanded(child: _WeekdayHeader(label: 'Thu')),
                    Expanded(child: _WeekdayHeader(label: 'Fri')),
                    Expanded(child: _WeekdayHeader(label: 'Sat')),
                    Expanded(child: _WeekdayHeader(label: 'Sun')),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Month Grid Rows
                ..._buildCalendarRows(context, isDark),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Day Agenda / Details (Same as Google Calendar)
          _buildDayAgendaSection(
            context,
            theme,
            isDark,
            selectedDayBookings,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarRows(BuildContext context, bool isDark) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Weekday of 1st day (1 = Mon, ..., 7 = Sun)
    final startWeekday = firstDayOfMonth.weekday;

    // Previous month padding days
    final prevMonthDays = DateTime(year, month, 0).day;
    final leadingDays = startWeekday - 1;

    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final rows = <Widget>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int weekIndex = 0; weekIndex < totalCells / 7; weekIndex++) {
      final weekCells = <Widget>[];

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final cellNumber = weekIndex * 7 + dayIndex;
        final dayOffset = cellNumber - leadingDays + 1;

        DateTime date;
        bool isCurrentMonth = true;

        if (dayOffset <= 0) {
          isCurrentMonth = false;
          final prevDay = prevMonthDays + dayOffset;
          date = DateTime(year, month - 1, prevDay);
        } else if (dayOffset > daysInMonth) {
          isCurrentMonth = false;
          final nextDay = dayOffset - daysInMonth;
          date = DateTime(year, month + 1, nextDay);
        } else {
          date = DateTime(year, month, dayOffset);
        }

        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        final dayBookings = _bookingsForDate(date);

        weekCells.add(
          Expanded(
            child: _buildDayCell(
              context: context,
              date: date,
              isCurrentMonth: isCurrentMonth,
              isToday: isToday,
              isSelected: isSelected,
              bookings: dayBookings,
              isDark: isDark,
            ),
          ),
        );
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: weekCells),
        ),
      );
    }

    return rows;
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime date,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required List<BookingModel> bookings,
    required bool isDark,
  }) {
    final confirmedCount =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completedCount =
        bookings.where((b) => b.status == BookingStatus.completed).length;
    final cancelledCount =
        bookings.where((b) => b.status == BookingStatus.cancelled).length;
    final noShowCount =
        bookings.where((b) => b.status == BookingStatus.noShow).length;

    final hasBookings = bookings.isNotEmpty;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
          if (!isCurrentMonth) {
            _focusedMonth = DateTime(date.year, date.month, 1);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.accent.withValues(alpha: 0.16)
                  : AppColors.accent.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.accent, width: 1.5)
              : (isToday
                  ? Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      width: 1,
                    )
                  : null),
        ),
        child: Column(
          children: [
            // Day Number Pill
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: isToday
                  ? const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: (isToday || isSelected)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isToday
                      ? Colors.black
                      : (!isCurrentMonth
                          ? (isDark
                              ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
                              : AppColors.textSecondary.withValues(alpha: 0.3))
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary)),
                ),
              ),
            ),

            const Spacer(),

            // Colored Status Count Badges
            if (hasBookings) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 1,
                children: [
                  if (confirmedCount > 0)
                    _buildCountDot(
                      count: confirmedCount,
                      color: AppColors.accent,
                    ),
                  if (completedCount > 0)
                    _buildCountDot(
                      count: completedCount,
                      color: AppColors.success,
                    ),
                  if (cancelledCount > 0)
                    _buildCountDot(
                      count: cancelledCount,
                      color: AppColors.error,
                    ),
                  if (noShowCount > 0)
                    _buildCountDot(
                      count: noShowCount,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCountDot({required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildDayAgendaSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<BookingModel> dayBookings,
  ) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormat.format(_selectedDate);

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
                  formattedDate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dayBookings.length} appointment${dayBookings.length == 1 ? '' : 's'} scheduled',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (dayBookings.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 36,
                  color: isDark
                      ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'No appointments on this day',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayBookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final booking = dayBookings[index];
              return _buildAgendaItemCard(context, booking, isDark);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAgendaItemCard(
    BuildContext context,
    BookingModel booking,
    bool isDark,
  ) {
    final timeFormat = DateFormat('h:mm a');
    final startTimeStr = timeFormat.format(booking.startAt);
    final endTimeStr = timeFormat.format(booking.endAt);

    return InkWell(
      onTap: () => _showBookingDetailsSheet(context, booking, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Time Column
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startTimeStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    endTimeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${booking.durationMinutes}m',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            // Vertical indicator
            Container(
              width: 3,
              height: 60,
              decoration: BoxDecoration(
                color: booking.status.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Middle info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getServiceName(booking),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      BookingStatusChip(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.customerName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking.fullPhoneNumber,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_getStaffName(booking) != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStaffName(booking)!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetailsSheet(
    BuildContext context,
    BookingModel booking,
    bool isDark,
  ) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeRange =
        '${timeFormat.format(booking.startAt)} - ${timeFormat.format(booking.endAt)} (${booking.durationMinutes} min)';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 4, right: 10),
                    decoration: BoxDecoration(
                      color: booking.status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getServiceName(booking),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${booking.id}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  BookingStatusChip(status: booking.status),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Date & Time Row
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(booking.startAt),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          timeRange,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Customer Row
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          booking.fullPhoneNumber,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Phone',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: booking.customerPhone),
                      );
                      AppToast.info(ctx, 'Phone copied');
                    },
                  ),
                ],
              ),

              if (_getStaffName(booking) != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.badge_rounded,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Specialist',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _getStaffName(booking)!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Price
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Price: \$${booking.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              if (booking.customerNotes != null &&
                  booking.customerNotes!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        booking.customerNotes!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Full Details'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (widget.onBookingTap != null) {
                          widget.onBookingTap!(booking);
                        } else {
                          context.push('/bookings/${booking.id}');
                        }
                      },
                    ),
                  ),
                  if (widget.onReschedule != null && booking.canReschedule) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        label: const Text('Reschedule'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          widget.onReschedule!(booking);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;

  const _WeekdayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
