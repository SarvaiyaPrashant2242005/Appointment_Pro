import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm(BookingModel booking) async {
    try {
      await ref.read(bookingsProvider.notifier).confirmBooking(booking.id);
      if (!mounted) return;
      AppToast.success(
        context,
        'Booking for ${booking.customerName} confirmed.',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to confirm booking: $e');
    }
  }

  Future<void> _handleComplete(BookingModel booking) async {
    try {
      await ref.read(bookingsProvider.notifier).completeBooking(booking.id);
      if (!mounted) return;
      AppToast.success(
        context,
        'Appointment for ${booking.customerName} marked as completed!',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to complete booking: $e');
    }
  }

  Future<void> _handleCancel(BookingModel booking) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Cancel Appointment',
      message:
          'Are you sure you want to cancel the appointment for ${booking.customerName}? This will free up the time slot.',
      confirmText: 'Cancel Appointment',
      cancelText: 'Keep',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await ref.read(bookingsProvider.notifier).cancelBooking(booking.id);
      if (!mounted) return;
      AppToast.info(context, 'Booking cancelled.');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, 'Failed to cancel booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBusiness = ref.watch(activeBusinessProvider);
    final bookingsAsync = ref.watch(bookingsProvider);
    final activeTab = ref.watch(bookingTabProvider);
    final statusFilter = ref.watch(bookingStatusFilterProvider);
    final filteredBookings = ref.watch(filteredBookingsProvider);

    // Compute counts for tabs
    final allBookings = bookingsAsync.value ?? [];
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayCount = allBookings
        .where(
          (b) =>
              !b.startAt.isBefore(startOfToday) &&
              !b.startAt.isAfter(endOfToday),
        )
        .length;
    final upcomingCount = allBookings
        .where((b) => b.startAt.isAfter(endOfToday))
        .length;
    final pastCount = allBookings
        .where((b) => b.startAt.isBefore(startOfToday))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bookings'),
            if (activeBusiness != null)
              Text(
                activeBusiness.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share Booking Page & QR',
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => context.push('/share-booking'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(bookingsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: activeBusiness == null
          ? const AppEmptyView(
              icon: Icons.storefront_outlined,
              title: 'No Active Business',
              message:
                  'Please create or select an active business to view bookings.',
            )
          : bookingsAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (err, _) => AppErrorView(
                message: err.toString(),
                onRetry: () => ref.read(bookingsProvider.notifier).refresh(),
              ),
              data: (_) => RefreshIndicator(
                onRefresh: () => ref.read(bookingsProvider.notifier).refresh(),
                child: Column(
                  children: [
                    // Search & Quick Share Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                ref
                                    .read(bookingSearchQueryProvider.notifier)
                                    .updateQuery(val);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search customer, phone, notes...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref
                                              .read(
                                                bookingSearchQueryProvider
                                                    .notifier,
                                              )
                                              .updateQuery('');
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.darkInputFill
                                    : AppColors.inputFill,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => context.push('/share-booking'),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share Link'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Segmented Tabs: Today, Upcoming, Past
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildTabItem(
                              label: 'Today',
                              count: todayCount,
                              tab: BookingListTab.today,
                              isActive: activeTab == BookingListTab.today,
                            ),
                            _buildTabItem(
                              label: 'Upcoming',
                              count: upcomingCount,
                              tab: BookingListTab.upcoming,
                              isActive: activeTab == BookingListTab.upcoming,
                            ),
                            _buildTabItem(
                              label: 'Past',
                              count: pastCount,
                              tab: BookingListTab.past,
                              isActive: activeTab == BookingListTab.past,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Status Filters Strip
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            isSelected: statusFilter == null,
                            onTap: () {
                              ref
                                  .read(bookingStatusFilterProvider.notifier)
                                  .setFilter(null);
                            },
                          ),
                          const SizedBox(width: 6),
                          ...BookingStatus.values.map((status) {
                            final isSelected = statusFilter == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _buildFilterChip(
                                label: status.displayLabel,
                                isSelected: isSelected,
                                activeColor: status.color,
                                onTap: () {
                                  ref
                                      .read(
                                        bookingStatusFilterProvider.notifier,
                                      )
                                      .setFilter(isSelected ? null : status);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Bookings List
                    Expanded(
                      child: filteredBookings.isEmpty
                          ? AppEmptyView(
                              icon: Icons.calendar_today_outlined,
                              title: _getEmptyTitle(activeTab),
                              message: _getEmptyMessage(activeTab),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = filteredBookings[index];
                                return BookingCard(
                                  booking: booking,
                                  onTap: () =>
                                      context.push('/bookings/${booking.id}'),
                                  onConfirm: booking.canConfirm
                                      ? () => _handleConfirm(booking)
                                      : null,
                                  onComplete: booking.canComplete
                                      ? () => _handleComplete(booking)
                                      : null,
                                  onCancel: booking.canCancel
                                      ? () => _handleCancel(booking)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required int count,
    required BookingListTab tab,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(bookingTabProvider.notifier).selectTab(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? AppColors.accent : AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark
                              ? Colors.black.withOpacity(0.15)
                              : Colors.white.withOpacity(0.2))
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = activeColor ?? AppColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? color
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  String _getEmptyTitle(BookingListTab tab) {
    switch (tab) {
      case BookingListTab.today:
        return 'No Appointments Today';
      case BookingListTab.upcoming:
        return 'No Upcoming Bookings';
      case BookingListTab.past:
        return 'No Past Bookings';
    }
  }

  String _getEmptyMessage(BookingListTab tab) {
    switch (tab) {
      case BookingListTab.today:
        return 'Your schedule is clear for today. Share your booking link to accept appointments.';
      case BookingListTab.upcoming:
        return 'You have no future bookings scheduled.';
      case BookingListTab.past:
        return 'No past booking records found.';
    }
  }
}
