import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/booking_slot_model.dart';

class BookingTimeSlots extends StatelessWidget {
  final List<BookingSlot> slots;
  final BookingSlot? selectedSlot;
  final ValueChanged<BookingSlot> onSlotSelected;

  const BookingTimeSlots({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No Available Time Slots',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All slots for this day are either fully booked, outside working hours, or in the past. Please select another date or staff member.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final morningSlots = slots
        .where((s) => s.period == SlotPeriod.morning)
        .toList();
    final afternoonSlots = slots
        .where((s) => s.period == SlotPeriod.afternoon)
        .toList();
    final eveningSlots = slots
        .where((s) => s.period == SlotPeriod.evening)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (morningSlots.isNotEmpty) ...[
          _buildPeriodSection(
            context: context,
            title: 'Morning',
            icon: Icons.wb_sunny_outlined,
            slots: morningSlots,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],
        if (afternoonSlots.isNotEmpty) ...[
          _buildPeriodSection(
            context: context,
            title: 'Afternoon',
            icon: Icons.wb_twilight_rounded,
            slots: afternoonSlots,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ],
        if (eveningSlots.isNotEmpty) ...[
          _buildPeriodSection(
            context: context,
            title: 'Evening',
            icon: Icons.nightlight_round,
            slots: eveningSlots,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildPeriodSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<BookingSlot> slots,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${slots.length} available)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = selectedSlot?.start == slot.start;

            return InkWell(
              onTap: () => onSlotSelected(slot),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : (isDark ? AppColors.darkSurface : AppColors.surface),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  slot.formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.black
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
