import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../staff/data/models/staff_model.dart';

class BookingStaffSelector extends StatelessWidget {
  final List<StaffModel> eligibleStaff;
  final StaffModel? selectedStaff;
  final ValueChanged<StaffModel?> onSelect;

  const BookingStaffSelector({
    super.key,
    required this.eligibleStaff,
    required this.selectedStaff,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (eligibleStaff.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 44,
                color: isDark
                    ? AppColors.darkTextSecondary.withOpacity(0.5)
                    : AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No specific staff are assigned to this service.\nWe will automatically assign an available specialist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => onSelect(null),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Proceed with Any Available'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isAnySelected = selectedStaff == null;

    return Column(
      children: [
        // Option 1: "Any Available Staff" (auto-assignment)
        InkWell(
          onTap: () => onSelect(null),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAnySelected
                  ? AppColors.accent.withOpacity(isDark ? 0.15 : 0.08)
                  : (isDark ? AppColors.darkSurface : AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAnySelected
                    ? AppColors.accent
                    : (isDark ? AppColors.darkBorder : AppColors.border),
                width: isAnySelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Any Available Specialist',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Maximum schedule availability & fastest booking',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAnySelected
                          ? AppColors.accent
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: 2,
                    ),
                    color: isAnySelected
                        ? AppColors.accent
                        : Colors.transparent,
                  ),
                  child: isAnySelected
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // List of specific staff
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: eligibleStaff.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final staff = eligibleStaff[index];
            final isSelected = selectedStaff?.id == staff.id;

            return InkWell(
              onTap: () => onSelect(staff),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(isDark ? 0.15 : 0.08)
                      : (isDark ? AppColors.darkSurface : AppColors.surface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : AppColors.border,
                      child: Text(
                        staff.name.isNotEmpty
                            ? staff.name.substring(0, 1).toUpperCase()
                            : 'S',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (staff.phone != null &&
                              staff.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              staff.phone!,
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
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
