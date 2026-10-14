import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../bussiness_setup/presentation/providers/business_provider.dart';
import '../../data/models/availability_model.dart';
import '../providers/availability_provider.dart';
import '../widgets/time_off_form.dart';
import '../widgets/working_hours_card.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTimeOffSheet(
    BuildContext context,
    String businessId, {
    TimeOffRecord? initialRecord,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final isEditing = initialRecord != null;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
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
                      Text(
                        isEditing
                            ? 'Edit Holiday or Time Off'
                            : 'Add Holiday or Time Off',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TimeOffForm(
                    businessId: businessId,
                    initialRecord: initialRecord,
                    onSubmit: (record) async {
                      try {
                        if (isEditing) {
                          await ref
                              .read(timeOffListProvider.notifier)
                              .updateTimeOff(record);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          AppToast.success(context, 'Holiday/Time-off updated.');
                        } else {
                          await ref
                              .read(timeOffListProvider.notifier)
                              .addTimeOff(record);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          AppToast.success(context, 'Holiday/Time-off saved.');
                        }
                      } catch (e) {
                        if (!mounted) return;
                        AppToast.error(context, 'Unable to save time off.');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteTimeOff(String id, String title) async {
    final confirmed = await AppConfirmDialog.showDelete(
      context,
      itemName: title,
      message: 'Delete this time off record?',
    );
    if (!confirmed) return;

    try {
      await ref.read(timeOffListProvider.notifier).deleteTimeOff(id);
      if (!mounted) return;
      AppToast.success(context, 'Record deleted.');
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to delete record.');
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final s = '${start.day}/${start.month}/${start.year}';
    final e = '${end.day}/${end.month}/${end.year}';
    return s == e ? s : '$s - $e';
  }

  Future<void> _handleApplyToAllOpenDays(
    int sourceDayIndex,
    DaySchedule sourceSchedule,
    BusinessAvailability availability,
  ) async {
    final otherOpenDays = availability.weeklySchedule.entries
        .where((e) => e.key != sourceDayIndex && e.value.isOpen)
        .map((e) => e.value.dayName)
        .toList();

    if (otherOpenDays.isEmpty) {
      AppToast.info(
        context,
        'No other open days to update. Turn on other days first.',
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.copy_all_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply ${sourceSchedule.dayName} to All Open Days?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Copies operating hours and break intervals',
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
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Operating Hours:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${sourceSchedule.openTime} - ${sourceSchedule.closeTime}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Breaks:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          sourceSchedule.breaks.isEmpty
                              ? 'None'
                              : '${sourceSchedule.breaks.length} break(s) (${sourceSchedule.breaks.map((b) => "${b.startTime}-${b.endTime}").join(", ")})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Applies to: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            otherOpenDays.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Apply to All',
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(availabilityProvider.notifier)
          .applyScheduleToDays(sourceDayIndex, openDaysOnly: true);
      if (!mounted) return;
      AppToast.success(
        context,
        'Applied ${sourceSchedule.dayName}\'s hours and breaks to all open days.',
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeBusiness = ref.watch(activeBusinessProvider);
    final availabilityAsync = ref.watch(availabilityProvider);
    final timeOffAsync = ref.watch(timeOffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Availability'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          tabs: const [
            Tab(text: 'Weekly Hours'),
            Tab(text: 'Holidays & Time Off'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Weekly Hours
          availabilityAsync.when(
            loading: () =>
                const Center(child: AppLoader(message: 'Loading schedule...')),
            error: (err, stack) => Center(
              child: AppErrorView(
                message: 'Unable to load working hours.',
                onRetry: () => ref.invalidate(availabilityProvider),
              ),
            ),
            data: (availability) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final dayIndex = index + 1; // 1 = Mon to 7 = Sun
                      final schedule = availability.weeklySchedule[dayIndex]!;

                      return WorkingHoursCard(
                        schedule: schedule,
                        onToggleOpen: (isOpen) async {
                          try {
                            await ref
                                .read(availabilityProvider.notifier)
                                .toggleDay(dayIndex, isOpen);
                          } catch (e) {
                            if (!context.mounted) return;
                            AppToast.error(
                              context,
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                        onHoursChanged: (open, close) async {
                          try {
                            await ref
                                .read(availabilityProvider.notifier)
                                .updateDayHours(
                                  dayIndex,
                                  openTime: open,
                                  closeTime: close,
                                );
                          } catch (e) {
                            if (!context.mounted) return;
                            AppToast.error(
                              context,
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                        onAddBreak: (breakRange) async {
                          try {
                            await ref
                                .read(availabilityProvider.notifier)
                                .addBreak(dayIndex, breakRange);
                            if (!context.mounted) return;
                            AppToast.success(context, 'Break added.');
                          } catch (e) {
                            if (!context.mounted) return;
                            AppToast.error(
                              context,
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                        onRemoveBreak: (breakIdx) async {
                          try {
                            await ref
                                .read(availabilityProvider.notifier)
                                .removeBreak(dayIndex, breakIdx);
                          } catch (e) {
                            if (!context.mounted) return;
                            AppToast.error(
                              context,
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                        onApplyToAllOpenDays: () => _handleApplyToAllOpenDays(
                          dayIndex,
                          schedule,
                          availability,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Tab 2: Holidays & Time Off
          timeOffAsync.when(
            loading: () =>
                const Center(child: AppLoader(message: 'Loading holidays...')),
            error: (err, stack) => Center(
              child: AppErrorView(
                message: 'Unable to load holidays.',
                onRetry: () => ref.invalidate(timeOffListProvider),
              ),
            ),
            data: (timeOffList) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scheduled Time Off (${timeOffList.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: activeBusiness != null
                                  ? () => _showTimeOffSheet(
                                      context,
                                      activeBusiness.id,
                                    )
                                  : null,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Time Off'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: timeOffList.isEmpty
                            ? Center(
                                child: AppEmptyView(
                                  title: 'No Time Off Scheduled',
                                  message:
                                      'Add public holidays, emergency closures, or staff vacations.',
                                  actionLabel: 'Add First Holiday',
                                  icon: Icons.event_available_outlined,
                                  onAction: activeBusiness != null
                                      ? () => _showTimeOffSheet(
                                          context,
                                          activeBusiness.id,
                                        )
                                      : null,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  24,
                                ),
                                itemCount: timeOffList.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final record = timeOffList[index];
                                  return AppCard(
                                    padding: const EdgeInsets.all(14),
                                    onTap: activeBusiness != null
                                        ? () => _showTimeOffSheet(
                                            context,
                                            activeBusiness.id,
                                            initialRecord: record,
                                          )
                                        : null,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.beach_access_outlined,
                                            color: AppColors.warning,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                _formatDateRange(
                                                  record.startDate,
                                                  record.endDate,
                                                ),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.accent,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              if (record.isBusinessWide)
                                                Text(
                                                  'Entire Business',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          color: AppColors.accent,
                                          tooltip: 'Edit Time Off',
                                          onPressed: activeBusiness != null
                                              ? () => _showTimeOffSheet(
                                                  context,
                                                  activeBusiness.id,
                                                  initialRecord: record,
                                                )
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20,
                                          ),
                                          color: AppColors.error,
                                          tooltip: 'Delete Time Off',
                                          onPressed: () => _handleDeleteTimeOff(
                                            record.id,
                                            record.title,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
