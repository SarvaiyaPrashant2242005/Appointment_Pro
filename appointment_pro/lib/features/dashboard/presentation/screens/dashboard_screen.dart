import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/register_provider.dart';
import '../../../availability/presentation/providers/availability_provider.dart';
import '../../../bussiness_setup/data/models/business_model.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../../bussiness_setup/presentation/widgets/business_form_sheet.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../bookings/presentation/providers/booking_provider.dart';
import '../../../bookings/presentation/widgets/booking_card.dart';
import '../widgets/dashboard_drawer.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = ref.read(localStorageServiceProvider);
    final todayBookings = ref.watch(todayBookingsProvider);
    final pendingBookings = todayBookings
        .where((b) => b.status.isActive)
        .toList();
    final completedCount = todayBookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final activeBusiness = ref.watch(activeBusinessProvider);
    final availabilityAsync = ref.watch(availabilityProvider);

    // Determine today's schedule (1 = Mon to 7 = Sun)
    final todayWeekday = DateTime.now().weekday;
    final todaySchedule =
        availabilityAsync.asData?.value.weeklySchedule[todayWeekday];

    return Scaffold(
      drawer: const DashboardDrawer(),
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildBusinessLogoButton(context, ref, activeBusiness),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting Header
            FutureBuilder<String?>(
              future: storage.getCurrentUserName(),
              builder: (context, snapshot) {
                final name = snapshot.data;
                final welcomeText = (name != null && name.isNotEmpty)
                    ? 'Welcome back, $name'
                    : 'Welcome to AppointmentPro';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      welcomeText,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Today's Operating Status Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (todaySchedule?.isOpen ?? true)
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      (todaySchedule?.isOpen ?? true)
                          ? Icons.store_rounded
                          : Icons.lock_clock_rounded,
                      color: (todaySchedule?.isOpen ?? true)
                          ? AppColors.success
                          : AppColors.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              todaySchedule?.dayName ?? 'Today',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: (todaySchedule?.isOpen ?? true)
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (todaySchedule?.isOpen ?? true)
                                    ? 'Open'
                                    : 'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (todaySchedule?.isOpen ?? true)
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (todaySchedule?.isOpen ?? true)
                              ? 'Hours: ${todaySchedule?.openTime ?? "09:00"} - ${todaySchedule?.closeTime ?? "18:00"}'
                              : 'Not accepting appointments today',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRouter.availability),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.accent,
                    ),
                    child: const Text(
                      'Hours',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2 State Cards: Completed and Pending
            _buildStateCards(context, theme, isDark, todayBookings),

            const SizedBox(height: 20),

            // Section: Today's Appointments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Appointments",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRouter.bookings),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkInputFill
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Text(
                      '${pendingBookings.length} Upcoming',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pendingBookings.isNotEmpty
                            ? AppColors.accent
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (pendingBookings.isEmpty)
              // Modern Empty Appointments State Card (Celebrates completion if completedCount > 0)
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              (completedCount > 0
                                      ? AppColors.success
                                      : AppColors.accent)
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          completedCount > 0
                              ? Icons.task_alt_rounded
                              : Icons.event_available_outlined,
                          size: 30,
                          color: completedCount > 0
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        completedCount > 0
                            ? 'All Caught Up for Today!'
                            : 'No Appointments for Today',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Text(
                          completedCount > 0
                              ? 'You have completed all $completedCount scheduled appointments for today. You can review them in the full appointments calendar.'
                              : 'Your daily scheduled bookings will appear here. Share your booking link with customers to fill your calendar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRouter.shareBooking),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                            label: const Text('Share Link & QR'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.tonalIcon(
                            onPressed: () => context.push(AppRouter.bookings),
                            icon: const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                            ),
                            label: const Text('View All'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              // Dynamic list of today's pending appointments (Only pending/active ones)
              Column(
                children: [
                  ...pendingBookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BookingCard(
                        booking: booking,
                        margin: EdgeInsets.zero,
                        onTap: () => context.push('/bookings/${booking.id}'),
                        onConfirm: booking.canConfirm
                            ? () async {
                                try {
                                  await ref
                                      .read(bookingsProvider.notifier)
                                      .confirmBooking(booking.id);
                                  if (context.mounted) {
                                    AppToast.success(
                                      context,
                                      'Booking for ${booking.customerName} confirmed.',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.error(
                                      context,
                                      'Failed to confirm booking: $e',
                                    );
                                  }
                                }
                              }
                            : null,
                        onComplete: booking.canComplete
                            ? () async {
                                try {
                                  await ref
                                      .read(bookingsProvider.notifier)
                                      .completeBooking(booking.id);
                                  if (context.mounted) {
                                    AppToast.success(
                                      context,
                                      'Appointment for ${booking.customerName} marked as completed!',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppToast.error(
                                      context,
                                      'Failed to complete appointment: $e',
                                    );
                                  }
                                }
                              }
                            : null,
                        onCancel: booking.canCancel
                            ? () async {
                                final confirmed = await AppConfirmDialog.show(
                                  context,
                                  title: 'Cancel Appointment',
                                  message:
                                      'Are you sure you want to cancel the appointment for ${booking.customerName}?',
                                  confirmText: 'Cancel Appointment',
                                  cancelText: 'Keep',
                                  isDestructive: true,
                                );
                                if (confirmed) {
                                  try {
                                    await ref
                                        .read(bookingsProvider.notifier)
                                        .cancelBooking(booking.id);
                                    if (context.mounted) {
                                      AppToast.info(
                                        context,
                                        'Appointment cancelled.',
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppToast.error(
                                        context,
                                        'Failed to cancel booking: $e',
                                      );
                                    }
                                  }
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push(AppRouter.bookings),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('View Full Appointments Calendar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateCards(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<BookingModel> todayBookings,
  ) {
    final completedCount = todayBookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final upcomingCount = todayBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;

    return Row(
      children: [
        // Completed State Card
        Expanded(
          child: _buildSingleStatCard(
            context: context,
            theme: theme,
            isDark: isDark,
            title: 'Completed',
            count: completedCount,
            subtitle: completedCount == 1
                ? '1 done today'
                : '$completedCount done today',
            icon: Icons.task_alt_rounded,
            accentColor: AppColors.success,
            onTap: () => context.push(AppRouter.bookings),
          ),
        ),
        const SizedBox(width: 12),
        // Upcoming State Card
        Expanded(
          child: _buildSingleStatCard(
            context: context,
            theme: theme,
            isDark: isDark,
            title: 'Upcoming',
            count: upcomingCount,
            subtitle: upcomingCount == 1
                ? '1 remaining'
                : '$upcomingCount remaining',
            icon: Icons.event_available_rounded,
            accentColor: AppColors.accent,
            onTap: () => context.push(AppRouter.bookings),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleStatCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: count > 0
                    ? accentColor
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                    : AppColors.textSecondary.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessLogoButton(
    BuildContext context,
    WidgetRef ref,
    BusinessModel? activeBusiness,
  ) {
    return Tooltip(
      message: activeBusiness != null
          ? 'Switch business (${activeBusiness.name})'
          : 'Switch Business',
      child: InkWell(
        onTap: () => _showQuickBusinessSwitcher(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.6),
              width: 1.6,
            ),
          ),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: _buildBusinessAvatarContent(activeBusiness),
          ),
        ),
      ),
    );
  }

  static Widget _buildBusinessAvatarContent(BusinessModel? business) {
    if (business?.logoPath != null && business!.logoPath!.isNotEmpty) {
      final file = File(business.logoPath!);
      return ClipOval(
        child: Image.file(
          file,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackInitial(business),
        ),
      );
    }
    return _buildFallbackInitial(business);
  }

  static Widget _buildFallbackInitial(BusinessModel? business) {
    if (business != null && business.name.trim().isNotEmpty) {
      return Text(
        business.name.trim()[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    }
    return const Icon(
      Icons.storefront_rounded,
      color: AppColors.accent,
      size: 18,
    );
  }

  void _showQuickBusinessSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Consumer(
          builder: (context, ref, _) {
            final businessListAsync = ref.watch(businessProvider);
            final activeBusiness = ref.watch(activeBusinessProvider);
            final businesses = businessListAsync.value ?? [];

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch Business',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select active business to manage',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Add Business',
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: AppColors.accent,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          showBusinessFormSheet(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Flexible(
                    child: businesses.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No businesses registered yet.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: businesses.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final b = businesses[index];
                              final isActive = b.id == activeBusiness?.id;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    if (!isActive) {
                                      await ref
                                          .read(businessProvider.notifier)
                                          .setActiveBusiness(b.id);
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      if (!context.mounted) return;
                                      AppToast.success(
                                        context,
                                        'Switched to ${b.name}',
                                      );
                                    } else {
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.accent.withValues(
                                              alpha: 0.1,
                                            )
                                          : (isDark
                                                ? AppColors.darkInputFill
                                                : AppColors.inputFill),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isActive
                                            ? AppColors.accent
                                            : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.border),
                                        width: isActive ? 1.6 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.accent
                                              .withValues(alpha: 0.15),
                                          child: _buildBusinessAvatarContent(b),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.name,
                                                style: TextStyle(
                                                  fontWeight: isActive
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                b.type == 'Other'
                                                    ? (b.otherType ??
                                                          'Business')
                                                    : b.type,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.success
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: AppColors.success,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.success,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go(AppRouter.businessList);
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Manage All Businesses'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
